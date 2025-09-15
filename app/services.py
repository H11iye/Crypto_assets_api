import requests

BINANCE_API_URL= "https://api.binance.com/api/v3/ticker/price"

def get_crypto_price(symbol: str, base: str="USDT") -> float:
    """Fetch the current price of a cryptocurrency from Binance API."""

    pair = f"{symbol.upper()}{base.upper()}"
    url = f"{BINANCE_API_URL}?symbol={pair}"

    response = requests.get(url)
    if response.status_code != 200:
        raise ValueError(f"Error fetching data from Binance API: {response.status_code}")
    
    data = response.json()

    if "price" not in data:

        raise ValueError(f"Invalid response data: {data}")
    
    return round(float(data["price"]), 2)
