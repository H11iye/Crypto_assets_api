#Stage 1: Build dependencies
FROM python:3.12-slim AS builder

WORKDIR /app

#Install dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

#Stage 2: Runtime the image
FROM python:3.12-slim
WORKDIR /app

#Copy installed dependencies from builder stage
COPY --from=builder /root/.local /root/.local

#Ensure installed binaries are in the PATH
ENV PATH=/root/.local/bin:$PATH

#Copy project files
COPY . .

#Run app with Gunicorn(production WSGI server)
CMD [ "gunicorn", "-b", "0.0.0.0:8080", "app.main:create_app()" ]