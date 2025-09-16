# app/routes.py
from flask import jsonify
from app.service import get_crypto_price

def register_routes(app):
    @app.route("/")
    def home():
        return jsonify({"message": "Binance Crypto API is running!"})

    @app.route("/crypto/<symbol>")
    def crypto_price(symbol):
        try:
            price = get_crypto_price(symbol)
            return jsonify({"symbol": symbol.upper(), "price": price, "currency": "USDT"})
        except Exception as e:
            return jsonify({"error": str(e)}), 400
