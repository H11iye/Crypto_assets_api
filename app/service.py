import requests

BINANCE_API_URL = "https://api.binance.com/api/v3/ticker/price"

def get_crypto_price(symbol: str, base: str = "USDT") -> dict:
    pair = f"{symbol.upper()}{base.upper()}"
    url = f"{BINANCE_API_URL}?symbol={pair}"
    response = requests.get(url, timeout=5)

    if response.status_code != 200:
        return None

    data = response.json()
    if "price" not in data:
        return None

    return {"symbol": symbol.upper(), "price": data["price"]}
