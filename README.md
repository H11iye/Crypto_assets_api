# Crypto Price API

A simple Flask-based API that fetches real-time cryptocurrency prices using the Binance API.  
Built with **Python + Flask**, tested with **pytest**, and containerized with **Docker**.  
Ready for deployment on **Google Cloud Run**.

---

## 🚀 Features
- `/crypto/<symbol>` → Get real-time price for a given symbol (e.g., BTCUSDT, ETHUSDT).  
- `/health` → Health check endpoint (for CI/CD & Cloud Run monitoring).  
- Unit tests with mocked Binance API for reliable CI/CD pipelines.  
- Dockerfile + GitHub Actions + GCP App Engine/Cloud Run ready.

---

## 📦 Installation

```bash
# Clone the repo
git clone https://github.com/your-username/crypto-price-api.git
cd crypto-price-api

# Create virtual environment
python3 -m venv venv
source venv/bin/activate   # Linux / Mac
venv\Scripts\activate      # Windows

# Install dependencies
pip install -r requirements.txt

## ▶️ Running Locally
# Run the Flask app
python -m app.main

## 🌐 API Endpoints
1. Get Crypto Price

Request

GET /crypto/<symbol>


Example

curl http://127.0.0.1:8080/crypto/BTCUSDT


Response

{
  "symbol": "BTCUSDT",
  "price": "67500.01"
}

2. Health Check

Request

GET /health


Example

curl http://127.0.0.1:8080/health


Response

{
  "status": "ok"
}

🧪 Running Tests
pytest

🐳 Docker
# Build image
docker build -t crypto-price-api .

# Run container
docker run -p 8080:8080 crypto-price-api

