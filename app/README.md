# Sample service — the thing to ship

This is the raw application for the take-home. It is intentionally **not** productionized:
no Dockerfile, no Kubernetes manifests, no Terraform, no CI. That's your job — see
[`../assignment.pdf`](../assignment.pdf).

## What it is
A tiny HTTP API (FastAPI) that exposes Prometheus metrics.

| Endpoint | Purpose |
|----------|---------|
| `GET /` | basic info |
| `GET /health` | liveness/readiness (200) |
| `GET /work` | simulates CPU + variable latency (drive load / HPA / latency panels) |
| `GET /metrics` | Prometheus metrics: `app_requests_total`, `app_in_flight_requests`, `app_request_duration_seconds` |

## Run it locally (sanity check)
```bash
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 8000
# then: curl localhost:8000/health && curl localhost:8000/metrics
```

You may change the app if you have a good reason (say why in your README), but you don't need to —
the assignment is about the infrastructure around it.
