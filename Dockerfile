# -------- Builder Stage --------
FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_VIRTUALENVS_CREATE=false

WORKDIR /app

# Install system dependencies
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates build-essential \
  && rm -rf /var/lib/apt/lists/*  

# Copy only requirements to leverage Docker cache
# -------- Install pip deps before copying the app source to take advantage of Docker layer caching --------

COPY app/requirements.txt /app/requirements.txt
RUN python -m pip install --upgrade pip \  
    && pip install --no-cache-dir -r /app/requirements.txt 

# -------- Copy app source --------
COPY app /app/app
COPY start.sh /app/start.sh

# -------- Create an unprivileged user and switch to it --------

RUN useradd --create-home appuser \
    && chown -R appuser:appuser /app
USER appuser

# -------- Expose the port and set the working directory --------
WORKDIR /app
EXPOSE 80

# -------- Entrypoint --------

CMD [ "/app/start.sh" ]