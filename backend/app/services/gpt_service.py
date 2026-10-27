"""
Tarif üretim servisi.

Şu an: Google Gemini API (ücretsiz)
OpenAI'ya geçmek için dosyanın altındaki yorumu kaldır.
"""
import os
import json
from typing import List, Optional
import google.generativeai as genai

from app.models.recipe import Recipe, RecipeIngredient, NutritionInfo

_model = None


def _get_model():
    global _model
    if _model is None:
        api_key = os.getenv("GEMINI_API_KEY", "")
        genai.configure(api_key=api_key)
        _model = genai.GenerativeModel(
            model_name="gemini-2.5-flash",
            generation_config=genai.GenerationConfig(
                temperature=0.7,
                response_mime_type="application/json",
            ),
        )
    return _model


def _build_prompt(ingredients: List[str], preferences: dict) -> str:
    dietary = preferences.get("dietary", [])
    allergies = preferences.get("allergies", [])
    servings = preferences.get("servings", 2)
    cuisine = preferences.get("cuisine", "")

    dietary_str = ", ".join(dietary) if dietary else "kısıtlama yok"
    allergy_str = ", ".join(allergies) if allergies else "alerji yok"
    cuisine_str = f"Mutfak türü: {cuisine}. " if cuisine else ""

    return f"""Sen profesyonel bir şef asistanısın. Aşağıdaki malzemelerle {servings} kişilik bir tarif oluştur.

Mevcut malzemeler: {', '.join(ingredients)}
Diyet tercihleri: {dietary_str}
Alerjiler (KESINLIKLE KULLANMA): {allergy_str}
{cuisine_str}

KURALLAR:
- Alerjik malzemeleri ASLA kullanma.
- Diyet tercihlerine %100 uy.
- Yanıtı YALNIZCA aşağıdaki JSON formatında döndür, başka hiçbir metin ekleme.

{{
  "title": "Tarif Adı",
  "ingredients": [
    {{"name": "malzeme adı", "amount": "miktar", "unit": "birim"}}
  ],
  "steps": ["Adım 1...", "Adım 2..."],
  "nutrition": {{
    "calories": 0,
    "protein": 0,
    "carbs": 0,
    "fat": 0
  }},
  "cook_time": 0,
  "difficulty": "Kolay",
  "category": "Ana Yemek"
}}

difficulty değerleri: Kolay | Orta | Zor
category değerleri: Ana Yemek | Kahvaltı | Tatlı | Çorba | Salata | Atıştırmalık
cook_time birimi dakikadır.
nutrition birimleri: calories=kcal, protein/carbs/fat=gram"""


async def generate_recipe(ingredients: List[str], preferences: dict) -> Recipe:
    if len(ingredients) < 2:
        raise ValueError("En az 2 malzeme gereklidir (BR-4).")

    prompt = _build_prompt(ingredients, preferences)
    model = _get_model()

    response = model.generate_content(prompt)
    raw = response.text

    # Gemini bazen ```json ``` bloku içinde döndürür, temizle
    if "```" in raw:
        raw = raw.split("```")[1]
        if raw.startswith("json"):
            raw = raw[4:]

    data = json.loads(raw.strip())

    recipe = Recipe(
        title=data["title"],
        ingredients=[RecipeIngredient(**i) for i in data["ingredients"]],
        steps=data["steps"],
        nutrition=NutritionInfo(**data["nutrition"]),
        cook_time=int(data.get("cook_time", 0)),
        difficulty=data.get("difficulty", "Kolay"),
        category=data.get("category", "Ana Yemek"),
    )
    return recipe


# ──────────────────────────────────────────────────────────────────────────────
# OpenAI'ya geçmek istediğinde:
#
# 1. requirements.txt'te openai==1.30.1 satırını aktif bırak
# 2. Bu dosyayı şu içerikle değiştir:
#
#   from openai import AsyncOpenAI
#   _client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
#
#   async def generate_recipe(...):
#       response = await _client.chat.completions.create(
#           model="gpt-4o-mini",
#           messages=[{"role":"user","content": prompt}],
#           response_format={"type":"json_object"},
#       )
#       data = json.loads(response.choices[0].message.content)
#       ...
# ──────────────────────────────────────────────────────────────────────────────
