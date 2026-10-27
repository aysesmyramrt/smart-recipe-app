from fastapi import APIRouter, Depends, HTTPException, Request, status
from slowapi import Limiter
from slowapi.util import get_remote_address
import os

from app.models.recipe import Recipe, RecipeGenerateRequest, FavoriteItem, HistoryItem, RecipeComment, CommentRequest
from app.utils.auth_middleware import verify_token
from app.services.gpt_service import generate_recipe
from app.services import firebase_service as fb
from typing import List

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)

RATE_LIMIT = os.getenv("RECIPE_RATE_LIMIT", "10/hour")


@router.post("/generate", response_model=Recipe)
@limiter.limit(RATE_LIMIT)
async def generate(
    request: Request,
    body: RecipeGenerateRequest,
    payload: dict = Depends(verify_token),
):
    uid = payload["sub"]
    user_doc = fb.get_user_document(uid) or {}
    user_prefs = user_doc.get("preferences", {})

    # Merge request-level preferences with stored user preferences
    merged_prefs = {**user_prefs, **body.preferences}

    try:
        recipe = await generate_recipe(body.ingredients, merged_prefs)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

    recipe_dict = recipe.model_dump(exclude={"id", "created_at"})
    recipe_id = fb.save_recipe(recipe_dict, uid)
    recipe.id = recipe_id
    return recipe


@router.get("/history", response_model=List[HistoryItem])
async def history(payload: dict = Depends(verify_token)):
    uid = payload["sub"]
    items = fb.get_history(uid)
    result = []
    for item in items:
        recipe_data = fb.get_recipe(item["recipe_id"])
        result.append(HistoryItem(
            recipe_id=item["recipe_id"],
            recipe=Recipe(**recipe_data) if recipe_data else None,
            viewed_at=item.get("viewedAt"),
        ))
    return result


@router.post("/favorites/{recipe_id}", status_code=status.HTTP_201_CREATED)
async def add_favorite(recipe_id: str, payload: dict = Depends(verify_token)):
    uid = payload["sub"]
    if not fb.get_recipe(recipe_id):
        raise HTTPException(status_code=404, detail="Tarif bulunamadı.")
    fb.add_favorite(uid, recipe_id)
    return {"detail": "Favorilere eklendi."}


@router.delete("/favorites/{recipe_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite(recipe_id: str, payload: dict = Depends(verify_token)):
    uid = payload["sub"]
    fb.remove_favorite(uid, recipe_id)


@router.get("/favorites", response_model=List[FavoriteItem])
async def get_favorites(payload: dict = Depends(verify_token)):
    uid = payload["sub"]
    items = fb.get_favorites(uid)
    return [FavoriteItem(recipe_id=i["recipe_id"], saved_at=i.get("savedAt")) for i in items]


@router.get("/popular/{title:path}", response_model=Recipe)
async def get_popular_recipe(title: str, payload: dict = Depends(verify_token)):
    recipe_data = fb.get_popular_recipe_by_title(title)
    if not recipe_data:
        raise HTTPException(status_code=404, detail="Tarif bulunamadı.")
    return Recipe(**recipe_data)


@router.get("/{recipe_id}/comments", response_model=List[RecipeComment])
async def get_comments(recipe_id: str, payload: dict = Depends(verify_token)):
    return fb.get_comments(recipe_id)


@router.post("/{recipe_id}/comments", response_model=RecipeComment)
async def add_comment(recipe_id: str, body: CommentRequest, payload: dict = Depends(verify_token)):
    uid = payload["sub"]
    user_doc = fb.get_user_document(uid) or {}
    display_name = user_doc.get("displayName", "Kullanıcı")
    return fb.add_comment(recipe_id, uid, display_name, body.text, body.rating)


@router.delete("/{recipe_id}/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_comment(recipe_id: str, comment_id: str, payload: dict = Depends(verify_token)):
    fb.delete_comment(recipe_id, comment_id)


@router.get("/{recipe_id}", response_model=Recipe)
async def get_recipe(recipe_id: str, payload: dict = Depends(verify_token)):
    recipe_data = fb.get_recipe(recipe_id)
    if not recipe_data:
        raise HTTPException(status_code=404, detail="Tarif bulunamadı.")
    return Recipe(**recipe_data)
