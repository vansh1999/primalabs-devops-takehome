# --------------------------------------------------
# Stage 1 - Builder
# --------------------------------------------------
FROM python:3.14.0-slim AS builder

WORKDIR /app

# Install only Python dependencies first for better layer caching
COPY app/requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# --------------------------------------------------
# Stage 2 - Runtime
# --------------------------------------------------
FROM python:3.14.0-slim

LABEL maintainer="Your Name"
LABEL description="PrimaLabs DevOps Take Home"

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Create non-root user
RUN addgroup --system app && \
    adduser --system --ingroup app app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application
COPY app/ .

RUN chown -R app:app /app

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uvicorn","app:app","--host","0.0.0.0","--port","8000"]