from flask import jsonify, request
from app.services.service import get_crypto_price

def register_routes(app):
    @app.route("/")
    def home():
        return jsonify({"message": "Crypto API is running!"})

    @app.route("/crypto/<symbol>")
    def crypto_price(symbol):
        try:
            price = get_crypto_price(symbol.upper())
            return jsonify({"symbol": symbol.upper(), "price": price})
        except Exception as e:
            return jsonify({"error": str(e)}), 400
