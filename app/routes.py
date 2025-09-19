# app/routes.py
# example endpoint to call n8n webhook async 
from fastapi import APIRouter, HTTPException
import httpx
import os
# from app.services.service import get_crypto_price

router = APIRouter()
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