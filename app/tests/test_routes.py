# app/tests/test_routes.py
from app.main import create_app

def test_home():
    app = create_app()
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert "Binance Crypto API" in response.get_json()["message"]

def test_crypto_endpoint():
    app = create_app()
    client = app.test_client()
    response = client.get("/crypto/BTC")
    assert response.status_code == 200
    data = response.get_json()
    assert "price" in data
    assert data["symbol"] == "BTC"
