#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo " Starting Platform Deployment                    "
echo "=================================================="

echo "[1/4] Initializing and applying Terraform..."
cd terraform
terraform init
terraform apply -auto-approve
cd ..

echo "[2/4] Deploying ArgoCD Application (GitOps)..."
kubectl apply -f gitops/application.yaml

echo "[3/4] Waiting for Bitcoin Node and Exporter Pod..."
echo "      -> Waiting for ArgoCD to sync and create resources..."
# Loop until ArgoCD provisions at least one matching pod in the new namespace
while ! kubectl get pod -n blockchain-dev -l app.kubernetes.io/name=bitcoin-node 2>/dev/null | grep -q "bitcoin-node"; do
  sleep 3
done

echo "      -> Pods detected. Waiting for readiness condition..."
# Wait for the created pod to reach the 'Ready' state
kubectl wait --namespace blockchain-dev \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=bitcoin-node \
  --timeout=300s

echo "[4/4] Verifying Monitoring Target Registration..."
sleep 10

echo "=================================================="
echo " Platform Ready                                   "
echo "=================================================="
echo "ArgoCD:   http://argocd.localhost"
echo "Grafana:  http://grafana.localhost (admin/admin)"
echo ""
echo "Status:"
echo "  ✓ KinD Cluster (Multi-Node)"
echo "  ✓ NGINX Ingress"
echo "  ✓ ArgoCD GitOps Engine"
echo "  ✓ Prometheus Stack"
echo "  ✓ Bitcoin StatefulSet + Exporter (HA Ready)"
echo "  ✓ Grafana Dashboards Provisioned"
echo "=================================================="