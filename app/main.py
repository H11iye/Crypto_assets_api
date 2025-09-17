from fastapi import FastAPI
from core.config import settings
from core.logging import setup_logging
from api import health, crypto_assets

setup_logging()

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        debug=settings.debug)
    
    @app.on_event("startup")
    async def startup(): pass

    @app.on_event("shutdown")
    async def shutdown(): pass

    app.include_router(health.router)
    app.include_router(crypto_assets.router, prefix="/v1")

    return app

app = create_app()

        
