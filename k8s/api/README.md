# API Manifests

Resources in this folder deploy the Fastify API into the cluster.

## Files

- `deployment.yaml` – Single-replica Deployment running the `api:v1` image with readiness/liveness probes and `envFrom` set to `api-config`
- `service.yaml` – ClusterIP Service exposing port `3000` inside the cluster
- `configmap.yaml` – Shared configuration (`DATABASE_URL`, `KAFKA_BROKER(S)`) consumed by the API and audit consumer

## Deploy

```bash
kubectl apply -f k8s/api
kubectl rollout status deploy/api
kubectl get pods -l app=api
```

Before applying, make sure `api:v1` is built from the project root and loaded into your cluster (for kind: `kind load docker-image api:v1 --name orders`). The API expects PostgreSQL and Redpanda DNS names (`postgres`, `redpanda`) to resolve inside the same namespace.


