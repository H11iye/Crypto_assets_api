# app/services/service.py
import httpx

BINANCE_API_URL = "https://api.binance.com/api/v3/ticker/price"

async def get_crypto_price(symbol: str, base: str = "USDT") -> float:
    """
    Fetch crypto price from Binance API (default pair: SYMBOL/USDT).
    Example: get_crypto_price("BTC") → BTCUSDT
    """
    pair = f"{symbol.upper()}{base.upper()}"
    url = f"{BINANCE_API_URL}?symbol={pair}"

    async with httpx.AsyncClient(timeout=5) as client:
        response = await client.get(url)

    if response.status_code != 200:
        raise ValueError(f"Error fetching {pair} price: {response.text}")

    data = response.json()
    if "price" not in data:
        raise ValueError(f"Invalid response for {pair}: {data}")

    return round(float(data["price"]), 2)
