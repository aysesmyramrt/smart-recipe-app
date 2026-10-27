from fastapi import APIRouter, HTTPException, status, Depends
from firebase_admin import auth as fb_auth
from passlib.context import CryptContext

from app.models.user import UserRegister, UserLogin, TokenResponse, UserProfile, DietaryPreferences
from app.utils.auth_middleware import verify_token, create_access_token
from app.services import firebase_service as fb

router = APIRouter()
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(body: UserRegister):
    try:
        user = fb_auth.create_user(
            email=body.email,
            password=body.password,
            display_name=body.display_name,
        )
    except fb_auth.EmailAlreadyExistsError:
        raise HTTPException(status_code=409, detail="Bu e-posta adresi zaten kayıtlı.")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    fb.create_user_document(user.uid, body.email, body.display_name)
    token, expires_in = create_access_token(user.uid, body.email)

    profile = UserProfile(
        uid=user.uid,
        email=body.email,
        display_name=body.display_name,
        preferences=DietaryPreferences(),
    )
    return TokenResponse(access_token=token, expires_in=expires_in, user=profile)


@router.post("/login", response_model=TokenResponse)
async def login(body: UserLogin):
    # Firebase Admin SDK doesn't expose password verification directly.
    # The recommended pattern is to verify via Firebase Auth REST API.
    import httpx, os

    api_key = os.getenv("FIREBASE_WEB_API_KEY", "")
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
    async with httpx.AsyncClient() as client:
        resp = await client.post(url, json={
            "email": body.email,
            "password": body.password,
            "returnSecureToken": True,
        })
    if resp.status_code != 200:
        raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı.")

    fb_data = resp.json()
    uid = fb_data["localId"]
    token, expires_in = create_access_token(uid, body.email)

    user_doc = fb.get_user_document(uid) or {}
    prefs_raw = user_doc.get("preferences", {})
    profile = UserProfile(
        uid=uid,
        email=body.email,
        display_name=user_doc.get("displayName", ""),
        preferences=DietaryPreferences(**prefs_raw),
    )
    return TokenResponse(access_token=token, expires_in=expires_in, user=profile)


@router.get("/profile", response_model=UserProfile)
async def get_profile(payload: dict = Depends(verify_token)):
    uid = payload["sub"]
    user_doc = fb.get_user_document(uid)
    if not user_doc:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    prefs_raw = user_doc.get("preferences", {})
    return UserProfile(
        uid=uid,
        email=user_doc.get("email", ""),
        display_name=user_doc.get("displayName", ""),
        preferences=DietaryPreferences(**prefs_raw),
    )
