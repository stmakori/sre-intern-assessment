#!/usr/bin/env bash
# Rebuilds the full Test 1 monitoring stack on a local kind cluster.
# Run from the repo root: ./test-1-monitoring/install.sh
set -euo pipefail
CONFIG=test-1-monitoring/config

echo ">>> Creating kind cluster (1 control plane + 2 workers)"
kind create cluster --config "$CONFIG/kind-cluster.yaml" --wait 120s
kubectl wait --for=condition=Ready nodes --all --timeout=180s

echo ">>> Adding Helm repos"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo ">>> Creating namespace and Grafana admin secret (random password, never committed)"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic grafana-admin -n monitoring \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$(openssl rand -base64 16)" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ">>> Installing Loki"
helm upgrade --install loki grafana/loki -n monitoring \
  -f "$CONFIG/loki-values.yaml" --wait --timeout 10m

echo ">>> Installing kube-prometheus-stack"
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring \
  -f "$CONFIG/kube-prometheus-stack-values.yaml" --wait --timeout 10m

echo ">>> Installing Alloy (log shipper DaemonSet)"
# Longer timeout: the first image pull on a slow connection exceeded 5 minutes
helm upgrade --install alloy grafana/alloy -n monitoring \
  -f "$CONFIG/alloy-values.yaml" \
  --set-file alloy.configMap.content="$CONFIG/alloy-config.alloy" \
  --wait --timeout 15m

echo ">>> Deploying test workloads"
kubectl apply -f "$CONFIG/test-workloads.yaml"

echo ">>> Applying alert rules"
kubectl apply -f test-1-monitoring/alerts/prometheus-rules.yaml

echo ">>> Done. Grafana password:"
kubectl get secret grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d; echo
echo "Access Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
