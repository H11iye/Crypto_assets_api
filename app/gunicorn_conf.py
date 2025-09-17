import multiprocessing
bind = "0.0.0.0:8000"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "uvicorn.workers.UvicornWorker"
max_requests = 1000
max_requests_jitter = 50
log_level = "info"
accesslog = "-"
error_log = "-"
graceful_timeout = 30
time_out = 60
keepalive = 5