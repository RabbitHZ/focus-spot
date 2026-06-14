from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://focusspot:focusspot@localhost:5432/focusspot"
    redis_url: str = "redis://localhost:6379"

    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 10080

    kakao_api_key: str = ""
    anthropic_api_key: str = ""

    environment: str = "development"

    model_config = {"env_file": ["../.env", ".env"]}


settings = Settings()
