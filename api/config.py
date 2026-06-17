from pathlib import Path

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://focusspot:focusspot@localhost:5433/focusspot"
    redis_url: str = "redis://localhost:6379"

    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 10080

    kakao_api_key: str = ""
    anthropic_api_key: str = ""
    google_client_id: str = ""
    google_client_secret: str = ""

    environment: str = "development"

    model_config = {
        "env_file": [
            str(Path(__file__).parent.parent / ".env"),
            str(Path(__file__).parent / ".env"),
        ],
        "extra": "ignore",
    }


settings = Settings()
