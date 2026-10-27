import re
from fastapi import HTTPException, status, UploadFile

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png"}
MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB


def validate_image(file: UploadFile) -> None:
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Sadece JPEG ve PNG görseller kabul edilmektedir.",
        )


async def validate_image_size(file: UploadFile) -> bytes:
    data = await file.read()
    if len(data) > MAX_IMAGE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Görsel boyutu 10MB'ı aşamaz.",
        )
    return data


def validate_password(password: str) -> None:
    if len(password) < 6:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Şifre en az 6 karakter olmalıdır.",
        )
