# app/routes.py
from fastapi import APIRouter, HTTPException
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
