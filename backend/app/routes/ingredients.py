from fastapi import APIRouter, UploadFile, File, Query, Depends
from app.models.ingredient import DetectionResult, IngredientSuggestion
from app.services.yolo_service import detect_ingredients
from app.utils.auth_middleware import verify_token
from app.utils.validators import validate_image, validate_image_size
from typing import List

router = APIRouter()

# Static suggestion list — replace with DB-backed autocomplete as the dataset grows
INGREDIENT_CATALOGUE: List[dict] = [
    {"name": "domates", "category": "sebze"},
    {"name": "soğan", "category": "sebze"},
    {"name": "sarımsak", "category": "sebze"},
    {"name": "patates", "category": "sebze"},
    {"name": "havuç", "category": "sebze"},
    {"name": "patlıcan", "category": "sebze"},
    {"name": "biber", "category": "sebze"},
    {"name": "kabak", "category": "sebze"},
    {"name": "ıspanak", "category": "sebze"},
    {"name": "marul", "category": "sebze"},
    {"name": "elma", "category": "meyve"},
    {"name": "muz", "category": "meyve"},
    {"name": "portakal", "category": "meyve"},
    {"name": "limon", "category": "meyve"},
    {"name": "tavuk göğsü", "category": "et"},
    {"name": "kıyma", "category": "et"},
    {"name": "dana eti", "category": "et"},
    {"name": "somon", "category": "balık"},
    {"name": "yumurta", "category": "süt ürünleri"},
    {"name": "süt", "category": "süt ürünleri"},
    {"name": "peynir", "category": "süt ürünleri"},
    {"name": "tereyağı", "category": "süt ürünleri"},
    {"name": "yoğurt", "category": "süt ürünleri"},
    {"name": "un", "category": "tahıl"},
    {"name": "pirinç", "category": "tahıl"},
    {"name": "makarna", "category": "tahıl"},
    {"name": "ekmek", "category": "tahıl"},
    {"name": "zeytinyağı", "category": "yağ"},
    {"name": "tuz", "category": "baharat"},
    {"name": "karabiber", "category": "baharat"},
    {"name": "kırmızı pul biber", "category": "baharat"},
    {"name": "kimyon", "category": "baharat"},
    {"name": "nane", "category": "baharat"},
]


@router.post("/detect", response_model=DetectionResult)
async def detect(
    file: UploadFile = File(...),
    _: dict = Depends(verify_token),
):
    validate_image(file)
    image_bytes = await validate_image_size(file)
    return detect_ingredients(image_bytes)


@router.get("/suggestions", response_model=List[IngredientSuggestion])
async def suggestions(
    q: str = Query(default="", min_length=1),
    _: dict = Depends(verify_token),
):
    q_lower = q.lower()
    matched = [
        IngredientSuggestion(**item)
        for item in INGREDIENT_CATALOGUE
        if q_lower in item["name"].lower()
    ]
    return matched[:10]
