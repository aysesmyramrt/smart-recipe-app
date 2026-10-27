from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime


class RecipeIngredient(BaseModel):
    name: str
    amount: str
    unit: str


class NutritionInfo(BaseModel):
    calories: float = 0
    protein: float = 0   # grams
    carbs: float = 0     # grams
    fat: float = 0       # grams


class Recipe(BaseModel):
    id: Optional[str] = None
    title: str
    ingredients: List[RecipeIngredient]
    steps: List[str]
    nutrition: NutritionInfo
    cook_time: int          # minutes
    difficulty: str         # Kolay | Orta | Zor
    category: str           # Ana Yemek | Kahvaltı | Tatlı | Çorba | Salata | Atıştırmalık
    image_url: Optional[str] = None
    created_at: Optional[datetime] = None
    generated_for: Optional[str] = None  # userId


class RecipeGenerateRequest(BaseModel):
    ingredients: List[str] = Field(min_length=2)
    preferences: Optional[dict] = Field(default_factory=dict)
    # preferences keys: dietary[], allergies[], servings, cuisine


class FavoriteItem(BaseModel):
    recipe_id: str
    saved_at: Optional[datetime] = None


class HistoryItem(BaseModel):
    recipe_id: str
    recipe: Optional[Recipe] = None
    viewed_at: Optional[datetime] = None


class RecipeComment(BaseModel):
    id: Optional[str] = None
    user_id: str
    display_name: str
    text: str
    rating: int
    created_at: Optional[str] = None


class CommentRequest(BaseModel):
    text: str
    rating: int
