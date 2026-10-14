#!/usr/bin/env bash
# Loads every dashboard JSON in this folder into Grafana.
# Each file becomes a ConfigMap labelled grafana_dashboard=1, which the
# Grafana sidecar (enabled in kube-prometheus-stack values) picks up automatically.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
for f in "$DIR"/*.json; do
  name="dashboard-$(basename "$f" .json)"
  kubectl create configmap "$name" -n monitoring --from-file="$f" --dry-run=client -o yaml | kubectl apply -f -
  kubectl label configmap "$name" -n monitoring grafana_dashboard=1 --overwrite
done
