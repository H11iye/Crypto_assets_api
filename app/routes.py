# app/routes.py

from fastapi import APIRouter, HTTPException
import httpx
import os
# from app.services.service import get_crypto_price
from app.services.service import get_crypto_price

router = APIRouter()

@router.get("/")
async def home():
    return {"message": "Crypto API is running!"}

@router.get("/crypto/{symbol}")
async def crypto_price(symbol: str):
    try:
        price = await get_crypto_price(symbol.upper())
        return {"symbol": symbol.upper(), "price": price}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# example endpoint to call n8n webhook async 

N8N_WEBHOOK = os.getenv("N8N_WEBHOOK_URL") # set in cloud run env

@router.post("/notify_n8n")
async def notify_n8n(payload: dict):
    if not N8N_WEBHOOK:
        raise HTTPException(500, "N8N_WEBHOOK_URL not configured")
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(N8N_WEBHOOK, json=payload)

    if resp.status_code >= 400:
        raise HTTPException(status_code=502, detail=f"n8n error: {resp.text}")
    
    return {"sent": True, "n8n_status": resp.status_code}