from fastapi import APIRouter, Depends
from app.models.user import DietaryPreferences
from app.utils.auth_middleware import verify_token
from app.services import firebase_service as fb

router = APIRouter()


@router.put("/preferences", response_model=DietaryPreferences)
async def update_preferences(
    body: DietaryPreferences,
    payload: dict = Depends(verify_token),
):
    uid = payload["sub"]
    fb.update_user_preferences(uid, body.model_dump())
    return body
