# app/tests/test_routes.py
import pytest
from app.main import create_app

#pytest.fixture
def client():
    app= create_app()
    app.config['TESTING'] = True
    return app.test_client()


def test_crypto_endpoint_success(monkeypatch, client):
    #Mock function to simulate successful API response
    def mock_get_crypto_price(symbol):
        return {"symbol": symbol.upper(), "price": 50000.00}
    
    #Patch the real function in service.py 
    from app import service
    monkeypatch.setattr(service, "get_crypto_price", mock_get_crypto_price)

    response = client.get("/crypto/BTC")
    assert response.status_code == 200
    data = response.get_json()
    assert data["symbol"] == "BTC"
    assert "price" in data

def test_crypto_endpoint_invalid_symbol(monkeypatch, client):
    #Mock function to simulate invalid symbol handling
    def mock_get_crypto_price(symbol):
        return None #Simulate Binanace returning no result
    
    from app import service
    monkeypatch.setattr(service, "get_crypto_price", mock_get_crypto_price)

    response = client.get("/crypto/INVALID")
    assert response.status_code == 404 # Expecting "Not Found"


def test_health_endpoint(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data == {"status": "ok"}