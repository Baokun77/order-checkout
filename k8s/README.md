# Kubernetes Manifests

This directory holds the manifests that deploy the full event-driven order stack.

## Layout

- `api/` – Fastify API Deployment + Service, consumes `api-config`
- `audit/` – Audit consumer Deployment, reuses the same ConfigMap
- `kafka/` – Single-node Redpanda deployment and ClusterIP Service

## Usage

```bash
# apply everything
kubectl apply -f k8s --recursive

# observe pods
kubectl get pods
```

Manifests assume the required images (`api:v1`, `audit-service:v1`) have already been built locally and loaded into the target cluster (e.g., via `kind load docker-image ...`). The `api-config` ConfigMap must exist before workloads start so that database and Kafka endpoints resolve correctly.


