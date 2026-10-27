from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime


class DietaryPreferences(BaseModel):
    dietary: List[str] = Field(default_factory=list)   # vegetarian, vegan, gluten-free, halal
    allergies: List[str] = Field(default_factory=list)  # peanuts, dairy, eggs, etc.
    language: str = "tr"
    notifications_enabled: bool = True


class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    display_name: str = Field(min_length=2, max_length=64)


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserProfile(BaseModel):
    uid: str
    email: str
    display_name: str
    created_at: Optional[datetime] = None
    preferences: DietaryPreferences = Field(default_factory=DietaryPreferences)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds
    user: UserProfile
