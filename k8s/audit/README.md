# Audit Consumer Manifests

This folder defines the Kubernetes Deployment for the Kafka audit consumer.

## Files

- `deployment.yaml` – Runs the `audit-service:v1` image with command `node dist/index.js` and injects configuration from `api-config`

## Deploy

```bash
kubectl apply -f k8s/audit
kubectl rollout status deploy/audit-service
kubectl logs -f deploy/audit-service
```

Ensure the following before applying:

- Image `audit-service:v1` is built from `services/audit-consumer` and loaded into the cluster
- `api-config` ConfigMap exists so the deployment receives `DATABASE_URL` and Kafka broker settings
- Redpanda (`redpanda` service) and PostgreSQL (`postgres` service) are reachable inside the namespace


