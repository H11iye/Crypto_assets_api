# app/service.py
import requests

BINANCE_API_URL = "https://api.binance.com/api/v3/ticker/price"

def get_crypto_price(symbol: str, base: str = "USDT") -> float:
    """
    Fetch crypto price from Binance API (default pair: SYMBOL/USDT).
    Example: get_crypto_price("BTC") → BTCUSDT
    """
    pair = f"{symbol.upper()}{base.upper()}"
    url = f"{BINANCE_API_URL}?symbol={pair}"
    response = requests.get(url, timeout=5)

    if response.status_code != 200:
        raise ValueError(f"Error fetching {pair} price: {response.text}")

    data = response.json()
    if "price" not in data:
        raise ValueError(f"Invalid response for {pair}: {data}")

    return round(float(data["price"]), 2)
