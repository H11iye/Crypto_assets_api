from fastapi import APIRouter
router = APIRouter()

@router.get("/price/{coin}")
def price(coin: str):
    # TODO: call coingecko, cache, push to n8n etc.
    
    return {"coin": coin, "price": "0.42"}