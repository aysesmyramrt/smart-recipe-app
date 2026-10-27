# AI-Powered Smart Recipe Recommendation System

Flutter (iOS/Android) + FastAPI backend + YOLOv8 + GPT-4o-mini + Firebase

---

> Not: Gizli anahtarlar ve Firebase yapılandırma dosyaları bu depoya dahil değildir; kendi Firebase projenle oluşturman gerekir. SRS ve bitirme raporu `docs/` klasöründe.

## Hızlı Başlangıç

### Backend

```bash
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# .env dosyasını düzenle: API anahtarlarını ekle

# Firebase credentials JSON dosyasını backend/ klasörüne koy
# Adını .env'deki FIREBASE_CREDENTIALS_PATH ile eşleştir

python run.py
# API → http://localhost:8000
# Docs → http://localhost:8000/docs  (sadece dev modunda)
```

### Frontend

```bash
cd frontend
flutter pub get
# android/app/google-services.json  (Firebase'den indir)
# ios/Runner/GoogleService-Info.plist
# lib/firebase_options.dart  (flutterfire configure ile üret)
# frontend/.env              (gerekli anahtarlar)

flutter run
```

---

## Ortam Değişkenleri (backend/.env)

| Değişken | Açıklama |
|---|---|
| `FIREBASE_CREDENTIALS_PATH` | Service account JSON yolu |
| `FIREBASE_STORAGE_BUCKET` | `project-id.appspot.com` |
| `FIREBASE_WEB_API_KEY` | Firebase Web API key (login için) |
| `OPENAI_API_KEY` | OpenAI API anahtarı |
| `JWT_SECRET_KEY` | Uzun, rastgele string |
| `YOLO_MODEL_PATH` | `models/yolov8n.pt` |
| `RECIPE_RATE_LIMIT` | `10/hour` (BR-7) |

---

## API Endpoint Özeti

| Method | Path | Açıklama |
|---|---|---|
| POST | `/auth/register` | Yeni kullanıcı kaydı |
| POST | `/auth/login` | JWT token al |
| GET | `/auth/profile` | Kullanıcı profili |
| POST | `/ingredients/detect` | YOLOv8 ile görsel analizi |
| GET | `/ingredients/suggestions?q=` | Otomatik tamamlama |
| POST | `/recipes/generate` | GPT ile tarif üret |
| GET | `/recipes/history` | Geçmiş tarifler |
| POST | `/recipes/favorites/{id}` | Favoriye ekle |
| DELETE | `/recipes/favorites/{id}` | Favoriden çıkar |
| GET | `/recipes/favorites` | Favori listesi |
| PUT | `/users/preferences` | Diyet tercihleri güncelle |

### Örnek: Tarif üret (curl)

```bash
curl -X POST http://localhost:8000/recipes/generate \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "ingredients": ["domates", "soğan", "sarımsak"],
    "preferences": {"dietary": ["vegan"], "servings": 2}
  }'
```

### Örnek: Görsel gönder (curl)

```bash
curl -X POST http://localhost:8000/ingredients/detect \
  -H "Authorization: Bearer <TOKEN>" \
  -F "file=@/path/to/image.jpg"
```

---

## Test

```bash
cd backend
pytest tests/ -v --tb=short
```

---

## Proje Yapısı

```
smart-recipe-app/
├── backend/
│   ├── app/
│   │   ├── __init__.py          # FastAPI app factory
│   │   ├── routes/              # auth, ingredients, recipes, users
│   │   ├── services/            # yolo_service, gpt_service, firebase_service
│   │   ├── models/              # Pydantic schemas
│   │   └── utils/               # JWT middleware, validators
│   ├── tests/
│   ├── requirements.txt
│   └── run.py
├── frontend/
│   └── lib/
│       ├── main.dart            # App entry + GoRouter
│       ├── screens/             # 6 ekran
│       ├── providers/           # Riverpod: auth, ingredient, recipe
│       ├── services/            # api_service, auth_service, camera_service
│       ├── models/              # recipe, ingredient, user
│       ├── widgets/             # ingredient_chip, recipe_card, nutrition_panel
│       └── utils/               # constants, theme
├── firestore.rules
├── storage.rules
└── firebase.json
```

---

## Geliştirme Aşamaları

1. **Veri Hazırlığı** — Firebase koleksiyonları + güvenlik kuralları + YOLOv8 testi
2. **UI** — Flutter ekranları (mock verilerle)
3. **AI Entegrasyonu** — YOLOv8 backend + GPT prompt engineering
4. **Uçtan Uca Akış** — Flutter → Backend → YOLOv8 → GPT → Firebase
5. **Test** — Unit + Integration + UAT

---

## Performans Hedefleri (SRS)

- Tarif üretimi < 10 sn
- Görsel tanıma < 5 sn
- DB sorguları < 2 sn
- 100 eş zamanlı kullanıcı
