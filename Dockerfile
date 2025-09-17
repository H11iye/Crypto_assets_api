#-----------Build Stage-----------
FROM python:3.12-slim AS builder
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY app/requirements.txt .
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir -r requirements.txt

#----------- runtime stage -----------
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN groupadd -r app && useradd -r -g app app

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
ENV PATH="opt/venv/bin:$PATH"
COPY app/ ./app

USER app 
EXPOSE 8000

CMD [ "gunicorn", "-c", "app/gunicorn_conf.py", "app.main:create_app()" ]