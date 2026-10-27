import firebase_admin
from firebase_admin import credentials, firestore, auth, storage
from datetime import datetime, timezone
from typing import Optional, List
import os

_db: Optional[firestore.Client] = None
_bucket = None

MAX_HISTORY_ITEMS = 50


def init_firebase() -> None:
    global _db, _bucket
    if not firebase_admin._apps:
        creds_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
        if creds_json:
            import json, base64
            cred_dict = json.loads(base64.b64decode(creds_json))
            cred = credentials.Certificate(cred_dict)
        else:
            cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
            cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(
            cred,
            {"storageBucket": os.getenv("FIREBASE_STORAGE_BUCKET", "")},
        )
    _db = firestore.client()
    _bucket = storage.bucket()


def get_db() -> firestore.Client:
    if _db is None:
        raise RuntimeError("Firebase başlatılmamış. init_firebase() çağırın.")
    return _db


# ── Users ─────────────────────────────────────────────────────────────────────

def create_user_document(uid: str, email: str, display_name: str) -> None:
    db = get_db()
    db.collection("users").document(uid).set(
        {
            "email": email,
            "displayName": display_name,
            "createdAt": datetime.now(tz=timezone.utc),
            "preferences": {
                "dietary": [],
                "allergies": [],
                "language": "tr",
                "notificationsEnabled": True,
            },
        }
    )


def get_user_document(uid: str) -> Optional[dict]:
    db = get_db()
    doc = db.collection("users").document(uid).get()
    return doc.to_dict() if doc.exists else None


def update_user_preferences(uid: str, preferences: dict) -> None:
    db = get_db()
    db.collection("users").document(uid).update({"preferences": preferences})


# ── Recipes ───────────────────────────────────────────────────────────────────

def save_recipe(recipe_data: dict, user_id: str) -> str:
    db = get_db()
    recipe_data["generatedFor"] = user_id
    recipe_data["createdAt"] = datetime.now(tz=timezone.utc)
    _, ref = db.collection("recipes").add(recipe_data)
    _append_history(user_id, ref.id)
    return ref.id


def get_recipe(recipe_id: str) -> Optional[dict]:
    db = get_db()
    doc = db.collection("recipes").document(recipe_id).get()
    if not doc.exists:
        return None
    data = doc.to_dict()
    data["id"] = doc.id
    return data


# ── Favorites ─────────────────────────────────────────────────────────────────

def add_favorite(user_id: str, recipe_id: str) -> None:
    db = get_db()
    db.collection("favorites").document(user_id).collection("items").document(recipe_id).set(
        {"savedAt": datetime.now(tz=timezone.utc)}
    )


def remove_favorite(user_id: str, recipe_id: str) -> None:
    db = get_db()
    db.collection("favorites").document(user_id).collection("items").document(recipe_id).delete()


def get_favorites(user_id: str) -> List[dict]:
    db = get_db()
    docs = db.collection("favorites").document(user_id).collection("items").order_by(
        "savedAt", direction=firestore.Query.DESCENDING
    ).stream()
    return [{"recipe_id": d.id, **d.to_dict()} for d in docs]


# ── History ───────────────────────────────────────────────────────────────────

def _append_history(user_id: str, recipe_id: str) -> None:
    db = get_db()
    col = db.collection("history").document(user_id).collection("items")
    col.document(recipe_id).set({"viewedAt": datetime.now(tz=timezone.utc)})

    # Enforce max 50 records (BR-10)
    all_items = list(col.order_by("viewedAt", direction=firestore.Query.ASCENDING).stream())
    if len(all_items) > MAX_HISTORY_ITEMS:
        for old in all_items[: len(all_items) - MAX_HISTORY_ITEMS]:
            col.document(old.id).delete()


def get_history(user_id: str) -> List[dict]:
    db = get_db()
    docs = (
        get_db()
        .collection("history")
        .document(user_id)
        .collection("items")
        .order_by("viewedAt", direction=firestore.Query.DESCENDING)
        .limit(MAX_HISTORY_ITEMS)
        .stream()
    )
    return [{"recipe_id": d.id, **d.to_dict()} for d in docs]


# ── Comments ──────────────────────────────────────────────────────────────────

def add_comment(recipe_id: str, user_id: str, display_name: str, text: str, rating: int) -> dict:
    db = get_db()
    _, ref = db.collection("recipes").document(recipe_id).collection("comments").add({
        "user_id": user_id,
        "display_name": display_name,
        "text": text,
        "rating": rating,
        "created_at": datetime.now(tz=timezone.utc).isoformat(),
    })
    return {"id": ref.id, "user_id": user_id, "display_name": display_name,
            "text": text, "rating": rating, "created_at": datetime.now(tz=timezone.utc).isoformat()}


def get_comments(recipe_id: str) -> List[dict]:
    db = get_db()
    docs = db.collection("recipes").document(recipe_id).collection("comments") \
             .order_by("created_at", direction=firestore.Query.DESCENDING).stream()
    return [{"id": d.id, **d.to_dict()} for d in docs]


def delete_comment(recipe_id: str, comment_id: str) -> None:
    db = get_db()
    db.collection("recipes").document(recipe_id).collection("comments").document(comment_id).delete()


# ── Popular recipe cache ───────────────────────────────────────────────────────

def get_popular_recipe_by_title(title: str) -> Optional[dict]:
    db = get_db()
    docs = db.collection("recipes").where("title", "==", title).limit(1).stream()
    for doc in docs:
        data = doc.to_dict()
        data["id"] = doc.id
        return data
    return None
