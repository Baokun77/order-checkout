# Redpanda (Kafka) Manifests

This directory contains a minimal single-node Redpanda deployment for local clusters.

## Files

- `deployment.yaml` – Runs `docker.redpanda.com/redpandadata/redpanda:v23.2.15` with dev-friendly flags and advertises the `redpanda` DNS name
- `service.yaml` – ClusterIP Service exposing port `9092` for in-cluster clients

## Deploy

```bash
kubectl apply -f k8s/kafka
kubectl rollout status deploy/redpanda
kubectl get svc redpanda
```

The manifest assumes:

- Workloads connect through the service DNS `redpanda:9092`
- No persistent storage (uses the container filesystem only)
- Security features such as SASL are disabled (`--set redpanda.enable_sasl=false`)

For production use, replace this setup with a multi-node Redpanda or Kafka installation that includes persistent volumes and authentication.


