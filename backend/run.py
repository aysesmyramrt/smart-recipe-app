import uvicorn
from dotenv import load_dotenv
import os

load_dotenv()

if __name__ == "__main__":
    uvicorn.run(
        "app:create_app",
        host=os.getenv("APP_HOST", "0.0.0.0"),
        port=int(os.getenv("APP_PORT", 8000)),
        reload=os.getenv("APP_ENV") == "development",
        factory=True,
    )
