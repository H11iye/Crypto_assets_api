# app/main.py
from fastapi import FastAPI
from app.routes import router

def create_app() -> FastAPI:
    app = FastAPI(title="Crypto Assets API", version="1.0.0")
    app.include_router(router)
    return app

app = create_app()

# Only needed if you want "python app/main.py" execution
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8080, reload=True)
