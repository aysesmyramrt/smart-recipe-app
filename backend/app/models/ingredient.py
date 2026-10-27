from pydantic import BaseModel, Field
from typing import List, Optional


class DetectedIngredient(BaseModel):
    name: str
    confidence: float = Field(ge=0.0, le=1.0)
    bounding_box: Optional[List[float]] = None  # [x1, y1, x2, y2]


class DetectionResult(BaseModel):
    ingredients: List[str]
    confidence_scores: List[float]
    raw_detections: List[DetectedIngredient] = Field(default_factory=list)
    suggestion: Optional[str] = None  # shown when no ingredients detected


class IngredientSuggestion(BaseModel):
    name: str
    category: str  # vegetable, fruit, meat, dairy, spice, etc.
