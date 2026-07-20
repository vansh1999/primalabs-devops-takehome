"""Minimal sample service for the PrimaLabs DevOps take-home.

Deliberately NOT productionized — no Dockerfile, no manifests, no config.
Your task (see ../assignment.pdf) is everything around it: containerize it,
deploy it to a local Kubernetes cluster via Terraform, and observe it in Grafana.

Endpoints:
  GET /         -> hello / basic info
  GET /health   -> 200 liveness/readiness
  GET /work     -> simulates CPU + variable latency (useful for load/HPA demos)
  GET /metrics  -> Prometheus metrics (request count, in-flight, latency histogram)

Run locally:
  pip install -r requirements.txt
  uvicorn app:app --host 0.0.0.0 --port 8000
"""

import os
import random
import time

from fastapi import FastAPI, Response
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
)

app = FastAPI(title="primalabs-devops-sample", version=os.getenv("APP_VERSION", "0.1.0"))

REQUESTS = Counter("app_requests_total", "Total HTTP requests", ["path", "status"])
IN_FLIGHT = Gauge("app_in_flight_requests", "In-flight requests")
LATENCY = Histogram(
    "app_request_duration_seconds",
    "Request latency (seconds)",
    ["path"],
    buckets=(0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10),
)


@app.middleware("http")
async def observe(request, call_next):
    IN_FLIGHT.inc()
    start = time.perf_counter()
    try:
        response = await call_next(request)
        status = response.status_code
    finally:
        IN_FLIGHT.dec()
    LATENCY.labels(request.url.path).observe(time.perf_counter() - start)
    REQUESTS.labels(request.url.path, str(status)).inc()
    return response


@app.get("/")
def root():
    return {"service": "primalabs-devops-sample", "version": app.version}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/work")
def work():
    # Burn a little CPU + add jittered latency, so load tests exercise HPA/latency panels.
    deadline = time.perf_counter() + random.uniform(0.02, 0.2)
    x = 0
    while time.perf_counter() < deadline:
        x += 1
    return {"iterations": x}


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
