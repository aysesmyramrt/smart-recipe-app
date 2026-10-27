from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from dotenv import load_dotenv
import os

from app.routes import auth, ingredients, recipes, users
from app.services.firebase_service import init_firebase

load_dotenv()

limiter = Limiter(key_func=get_remote_address)


def create_app() -> FastAPI:
    init_firebase()

    app = FastAPI(
        title="Smart Recipe API",
        version="1.0.0",
        docs_url="/docs" if os.getenv("APP_ENV") == "development" else None,
    )

    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    origins_env = os.getenv("CORS_ORIGINS", "*").strip()
    if origins_env == "*":
        origins = ["*"]
        use_credentials = False
    else:
        origins = [o.strip() for o in origins_env.split(",") if o.strip()]
        use_credentials = True

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=use_credentials,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth.router, prefix="/auth", tags=["auth"])
    app.include_router(ingredients.router, prefix="/ingredients", tags=["ingredients"])
    app.include_router(recipes.router, prefix="/recipes", tags=["recipes"])
    app.include_router(users.router, prefix="/users", tags=["users"])

    @app.get("/health")
    async def health():
        return {"status": "ok"}

    return app
