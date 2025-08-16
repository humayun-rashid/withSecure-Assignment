FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install deps first for better layer caching
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy source
COPY src/ ./src/

# Expose the app port that ALB will target
EXPOSE 8080
ENV PYTHONPATH=/app/src

# Production server: Gunicorn + Uvicorn worker (2 workers, 1 thread each)
# Tweak workers to 2 * vCPU for your task size (e.g., 2 workers for 0.25–0.5 vCPU)
CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "-w", "2", \
     "-b", "0.0.0.0:8080", "listservice.main:app", \
     "--access-logfile", "-", "--error-logfile", "-"]
