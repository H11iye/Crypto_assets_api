from flask import Blueprint, jsonify
from .service import get_crypto_price

bp = Blueprint("routes", __name__)

@bp.route("/crypto/<symbol>", methods=["GET"])
def crypto(symbol):
    data = get_crypto_price(symbol)
    if data:
        return jsonify(data), 200
    return jsonify({"error": "Invalid symbol"}), 404


@bp.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"}), 200
