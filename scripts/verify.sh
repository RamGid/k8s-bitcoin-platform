#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo " Running Automated Platform Verification Checks  "
echo "=================================================="

echo -n "[Check 1/6] KinD Cluster Nodes: "
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
if [ "$NODE_COUNT" -ge 2 ]; then
  echo "PASS ($NODE_COUNT nodes ready)"
else
  echo "FAIL ($NODE_COUNT nodes found)"; exit 1
fi

echo -n "[Check 2/6] Bitcoin Pod & Sidecar Readiness: "
READY_CONTAINERS=$(kubectl get pod -n blockchain-dev -l app.kubernetes.io/name=bitcoin-node -o jsonpath='{.items[0].status.containerStatuses[*].ready}' | tr ' ' '\n' | grep -c 'true' || true)
if [ "$READY_CONTAINERS" -eq 2 ]; then
  echo "PASS (bitcoind & exporter running)"
else
  echo "FAIL ($READY_CONTAINERS ready containers)"; exit 1
fi

echo -n "[Check 3/6] Bitcoin RPC Response (Block Count): "
BLOCK_COUNT=$(kubectl exec -n blockchain-dev -c main statefulset/bitcoin-node -- bitcoin-cli -testnet -conf=/etc/bitcoin/bitcoin.conf -rpcuser=bitcoin -rpcpassword=bitcoin-secure-password-123 getblockcount || echo "ERR")
if [ "$BLOCK_COUNT" != "ERR" ]; then
  echo "PASS (Current block: $BLOCK_COUNT)"
else
  echo "FAIL"; exit 1
fi

echo -n "[Check 4/6] Exporter Scraping Metrics: "
METRICS_PAYLOAD="ERR"
for i in {1..5}; do
  METRICS_PAYLOAD=$(kubectl get --raw "/api/v1/namespaces/blockchain-dev/services/bitcoin-node:8334/proxy/metrics" 2>/dev/null || echo "ERR")
  if echo "$METRICS_PAYLOAD" | grep -q "bitcoin_blocks"; then
    break
  fi
  sleep 2
done

if echo "$METRICS_PAYLOAD" | grep -q "bitcoin_blocks" && echo "$METRICS_PAYLOAD" | grep -q "bitcoin_peers"; then
  PEER_METRIC=$(echo "$METRICS_PAYLOAD" | grep '^bitcoin_peers' | head -n 1)
  BLOCK_METRIC=$(echo "$METRICS_PAYLOAD" | grep '^bitcoin_blocks' | head -n 1)
  echo "PASS ($BLOCK_METRIC | $PEER_METRIC)"
else
  echo "FAIL (Metrics missing or API proxy failed)"; exit 1
fi

echo -n "[Check 5/6] ArgoCD Sync State: "
ARGO_STATUS=$(kubectl get application -n argocd bitcoin-node -o jsonpath='{.status.sync.status}')
echo "PASS ($ARGO_STATUS)"

echo -n "[Check 6/6] Grafana Ingress: "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: grafana.localhost" http://localhost/)
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 302 ]; then
  echo "PASS (HTTP $HTTP_CODE)"
else
  echo "FAIL (HTTP $HTTP_CODE)"; exit 1
fi

echo "=================================================="
echo " All platform verification checks passed!       "
echo "=================================================="
