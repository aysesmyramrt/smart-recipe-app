from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from datetime import datetime, timezone
import os

bearer_scheme = HTTPBearer()


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)) -> dict:
    token = credentials.credentials
    secret = os.getenv("JWT_SECRET_KEY", "")
    algorithm = os.getenv("JWT_ALGORITHM", "HS256")

    try:
        payload = jwt.decode(token, secret, algorithms=[algorithm])
        if payload.get("exp") and datetime.fromtimestamp(payload["exp"], tz=timezone.utc) < datetime.now(tz=timezone.utc):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token süresi dolmuş")
        return payload
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Geçersiz token")


def create_access_token(uid: str, email: str) -> tuple[str, int]:
    expire_hours = int(os.getenv("JWT_EXPIRE_HOURS", 24))
    expire_seconds = expire_hours * 3600
    from datetime import timedelta
    exp = datetime.now(tz=timezone.utc) + timedelta(hours=expire_hours)

    payload = {"sub": uid, "email": email, "exp": exp}
    secret = os.getenv("JWT_SECRET_KEY", "")
    algorithm = os.getenv("JWT_ALGORITHM", "HS256")
    token = jwt.encode(payload, secret, algorithm=algorithm)
    return token, expire_seconds
