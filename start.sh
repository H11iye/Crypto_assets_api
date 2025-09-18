#!/usr/bin/env bash
set -e

# Use WEB_CONCURRENCY if set, otherwise auto-calc: (2 * CPU) + 1
if [ -n "${WEB_CONCURRENCY}" ]; then
  WORKERS="${WEB_CONCURRENCY}"
else
  WORKERS=$(python -c "import multiprocessing as m; print(max(1, (m.cpu_count() * 2) + 1))")
fi

exec gunicorn \
  -k uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:80 \
  --workers "$WORKERS" \
  --worker-connections 1000 \
  --timeout 30 \
  app.main:app
