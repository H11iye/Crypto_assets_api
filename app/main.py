from flask import Flask
from .routes import register_routes

def create_app():
    app = Flask(__name__)
    register_routes(app)   # call the function to attach routes
    return app

if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=8080, debug=True)
