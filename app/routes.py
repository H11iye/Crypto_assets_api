from flask import jsonify, request
from .services import get_crypto_price, get_historical_data

def register_routes(app):
    @app.route('/')
    def home():
        return ({"message": "Welcome to Binance Crypto Assets API!"})
    
    @app.route("/crypto/<symbol>")
    def crypto_price(symbol):
        try:
            price = get_crypto_price(symbol)
            return jsonify({"symbol": symbol.upper(), "price": price, "currency": "USDT"})
        except ValueError as e:
            return jsonify({"error": str(e)}), 400
        
        