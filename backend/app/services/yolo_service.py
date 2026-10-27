"""
Ingredient detection service.
1. Ozel egitilmis YOLOv8 modeli (51 sinif, Turk mutfagi) ile tespit
2. Hic sonuc cikmaz veya guven dusukse -> Gemini Vision ile destekle
"""
import os
import io
import base64
import json
import numpy as np
from PIL import Image
from typing import List
import google.generativeai as genai

from app.models.ingredient import DetectionResult, DetectedIngredient

# PyTorch 2.6+ uyumluluk: weights_only=False varsayilan yap
import torch as _torch
_orig_torch_load = _torch.load
def _patched_torch_load(*args, **kwargs):
    kwargs.setdefault("weights_only", False)
    return _orig_torch_load(*args, **kwargs)
_torch.load = _patched_torch_load

_yolo_model = None
_gemini_model = None

# Egitilmis modelin sinif isimlerinin Turkce karsiliklari (51 sinif)
FOOD_TR = {
    # Food Ingredients
    "banana": "muz",
    "tomato": "domates",
    "carrot": "havuc",
    "chicken": "tavuk",
    "lemon": "limon",
    "egg": "yumurta",
    "potato": "patates",
    "milk": "sut",
    "rice": "pirinc",
    "onion": "sogan",
    "cucumber": "salatalik",
    "cheese": "peynir",
    "cabbage": "lahana",
    "mushroom": "mantar",
    "eggplant": "patlican",
    "garlic": "sarimsak",
    "zucchini": "kabak",
    "yogurt": "yogurt",
    "sausage": "sucuk",
    "bell pepper": "biber",
    "bulgur": "bulgur",
    "chickpeas": "nohut",
    "farfalle pasta": "makarna",
    "fusilli pasta": "makarna",
    "green pepper": "yesil biber",
    "ground meat": "kiyma",
    "ketchup": "ketchup",
    "margarine": "margarin",
    "mayonnaise": "mayonez",
    "olive": "zeytin",
    "olive oil": "zeytinyagi",
    "parsley": "maydanoz",
    "red lentils": "kirmizi mercimek",
    "spaghetti": "spagetti",
    "tomato paste": "domates salcasi",
    "turkish dumplings": "manti",
    # Spices
    "basil": "fesleğen",
    "black pepper": "karabiber",
    "cinnamon": "tarcin",
    "garlic_powder": "sarimsak tozu",
    "onion_powder": "sogan tozu",
    "oregano": "kekik",
    "paprika": "paprika",
    "rosemary": "biberiye",
    "salt": "tuz",
    "thyme": "kekik",
    # Chicken parts
    "breast": "tavuk gogsu",
    "leg": "tavuk but",
    "quater": "tavuk but",
    "thigh": "tavuk but ustu",
    "wing": "tavuk kanadi",
}


def _get_yolo():
    global _yolo_model
    if _yolo_model is None:
        import torch
        import torch.serialization
        import ultralytics.nn.tasks
        import ultralytics.nn.modules.conv
        import torch.nn.modules.container
        import torch.nn.modules.activation
        import torch.nn.modules.batchnorm
        import torch.nn.modules.pooling
        import torch.nn.modules.upsampling
        # PyTorch 2.6+ icin tum gerekli sinifları ekle
        torch.serialization.add_safe_globals([
            ultralytics.nn.tasks.DetectionModel,
            ultralytics.nn.modules.conv.Conv,
            torch.nn.modules.container.Sequential,
            torch.nn.modules.activation.SiLU,
            torch.nn.modules.batchnorm.BatchNorm2d,
            torch.nn.modules.pooling.MaxPool2d,
            torch.nn.modules.upsampling.Upsample,
        ])
        from ultralytics import YOLO
        model_path = os.getenv("YOLO_MODEL_PATH", "models/food_ingredients.pt")
        _yolo_model = YOLO(model_path)
    return _yolo_model


def _get_gemini():
    global _gemini_model
    if _gemini_model is None:
        api_key = os.getenv("GEMINI_API_KEY", "")
        genai.configure(api_key=api_key)
        _gemini_model = genai.GenerativeModel("gemini-2.5-flash")
    return _gemini_model


def _detect_with_yolo(image_bytes: bytes) -> List[DetectedIngredient]:
    confidence_threshold = float(os.getenv("YOLO_CONFIDENCE_THRESHOLD", 0.15))

    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img_array = np.array(image)

    model = _get_yolo()
    results = model(img_array, verbose=False, imgsz=800)[0]

    # DEBUG: tum tespitleri logla (food filtresi oncesi)
    all_detections_debug = []
    for box in results.boxes:
        conf = float(box.conf[0])
        cls_id = int(box.cls[0])
        name = model.names.get(cls_id, f"id:{cls_id}")
        all_detections_debug.append(f"{name}({conf:.2f})")
    if all_detections_debug:
        print(f"[YOLO DEBUG] Ham tespitler (toplam {len(all_detections_debug)}): {all_detections_debug[:20]}")
    else:
        print(f"[YOLO DEBUG] Model hic tespit yapmadi! Goruntu boyutu: {img_array.shape}")

    detections = []
    seen = {}
    for box in results.boxes:
        conf = float(box.conf[0])
        cls_id = int(box.cls[0])
        if conf < confidence_threshold:
            continue
        english_name = model.names.get(cls_id, "").lower()
        turkish_name = FOOD_TR.get(english_name, english_name)  # Turkce yoksa ingilizce kullan
        if turkish_name in seen and conf <= seen[turkish_name]:
            continue
        seen[turkish_name] = conf
        raw_xyxy = box.xyxy[0]
        xyxy = raw_xyxy.tolist() if hasattr(raw_xyxy, "tolist") else list(raw_xyxy)
        detections.append(DetectedIngredient(name=turkish_name, confidence=conf, bounding_box=xyxy))

    return sorted(detections, key=lambda x: x.confidence, reverse=True)


def _detect_with_gemini(image_bytes: bytes) -> List[DetectedIngredient]:
    model = _get_gemini()
    image_data = base64.b64encode(image_bytes).decode("utf-8")

    prompt = """Bu fotograftaki yiyecek malzemelerini tespit et.
Sadece yiyecek/icecek malzemelerini listele, Turkce ad kullan.
Yaniti SADECE JSON formatinda dondur:
{"ingredients": [{"name": "malzeme", "confidence": 0.95}]}
Yiyecek yoksa: {"ingredients": []}"""

    try:
        response = model.generate_content([
            {"mime_type": "image/jpeg", "data": image_data},
            prompt
        ])
        raw = response.text.strip()
        if "```" in raw:
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        data = json.loads(raw.strip())
        return [
            DetectedIngredient(
                name=item["name"],
                confidence=float(item.get("confidence", 0.85)),
                bounding_box=[0, 0, 1, 1]
            )
            for item in data.get("ingredients", [])
        ]
    except Exception as e:
        print(f"[GEMINI ERROR] {type(e).__name__}: {e}")
        return []


def detect_ingredients(image_bytes: bytes) -> DetectionResult:
    # 1. Once YOLO ile dene
    yolo_results = []
    try:
        yolo_results = _detect_with_yolo(image_bytes)
        print(f"[YOLO] Tespit edildi: {[d.name for d in yolo_results]}")
    except Exception as e:
        print(f"[YOLO] Hata: {e}")

    # 2. YOLO az sonuc verdiyse Gemini ile destekle
    gemini_results = []
    if len(yolo_results) < 2:
        print(f"[YOLO] Yetersiz sonuc ({len(yolo_results)}), Gemini devreye giriyor...")
        try:
            gemini_results = _detect_with_gemini(image_bytes)
            print(f"[GEMINI] Tespit edildi: {[d.name for d in gemini_results]}")
        except Exception as e:
            print(f"[GEMINI] Hata: {e}")

    # 3. Sonuclari birlestir (tekrarlari kaldir)
    combined = {d.name: d for d in yolo_results}
    for d in gemini_results:
        if d.name not in combined:
            combined[d.name] = d

    detections = sorted(combined.values(), key=lambda x: x.confidence, reverse=True)

    if not detections:
        return DetectionResult(
            ingredients=[],
            confidence_scores=[],
            raw_detections=[],
            suggestion="Goruntude malzeme tespit edilemedi. Lutfen malzemeleri manuel olarak girin.",
        )

    return DetectionResult(
        ingredients=[d.name for d in detections],
        confidence_scores=[round(d.confidence, 3) for d in detections],
        raw_detections=detections,
    )
