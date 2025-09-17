from pydantic import BaseSettings

class Settings(BaseSettings):
    app_name: str = "Crypto Assets API"
    debug: bool = False
    workers: int = 2
    n8n_webhook_url: str = "http://n8n:5678/webhook"
    log_level: str = "INFO"

    class Config:
        env_file = ".env"

settings = Settings()