#!/usr/bin/env zsh
# Prometheus, Grafana, and monitoring tools configuration

# Prometheus CLI (promtool) aliases
alias pt='promtool'
alias ptcheck='promtool check config'
alias ptrules='promtool check rules'
alias ptquery='promtool query instant'
alias pttest='promtool test rules'

# Function to validate Prometheus config
prom_validate() {
    local config_file="${1:-prometheus.yml}"
    promtool check config "$config_file"
}

# Function to validate Prometheus rules
prom_validate_rules() {
    local rules_file="${1:-rules.yml}"
    promtool check rules "$rules_file"
}

# Function to query Prometheus (when port-forwarded)
prom_query() {
    local query="$1"
    local server="${2:-http://localhost:9090}"
    
    curl -s "${server}/api/v1/query" \
        --data-urlencode "query=${query}" | jq '.data.result'
}

# Function to port-forward Prometheus
prom_port_forward() {
    local port="${1:-9090}"
    local namespace="${2:-monitoring}"
    echo "Port-forwarding Prometheus to localhost:$port..."
    kubectl port-forward -n "$namespace" svc/prometheus-server "$port":80 &
    echo "Prometheus available at: http://localhost:$port"
}

# Function to port-forward Grafana
grafana_port_forward() {
    local port="${1:-3000}"
    local namespace="${2:-monitoring}"
    echo "Port-forwarding Grafana to localhost:$port..."
    kubectl port-forward -n "$namespace" svc/grafana "$port":80 &
    echo "Grafana available at: http://localhost:$port"
}

# Function to get Grafana admin password
grafana_get_password() {
    local namespace="${1:-monitoring}"
    kubectl get secret -n "$namespace" grafana -o jsonpath="{.data.admin-password}" | base64 -d
    echo
}

# Function to create a ServiceMonitor for Prometheus Operator
create_service_monitor() {
    local name="$1"
    local namespace="$2"
    local service="$3"
    local port="${4:-metrics}"
    
    cat <<EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ${name}
  namespace: ${namespace}
spec:
  selector:
    matchLabels:
      app: ${service}
  endpoints:
  - port: ${port}
    interval: 30s
    path: /metrics
EOF
}

# Function to create basic alerting rule
create_alert_rule() {
    local name="$1"
    local expr="$2"
    local severity="${3:-warning}"
    
    cat <<EOF
- alert: ${name}
  expr: ${expr}
  for: 5m
  labels:
    severity: ${severity}
  annotations:
    summary: "{{ \$labels.instance }}: ${name}"
    description: "{{ \$labels.instance }} has triggered ${name}"
EOF
}

# Aliases for common monitoring tasks
alias mon-pods='kubectl top pods'
alias mon-nodes='kubectl top nodes'
alias mon-events='kubectl get events --sort-by=".lastTimestamp"'

# Function to watch resource usage
watch_resources() {
    local namespace="${1:---all-namespaces}"
    watch -n 2 "kubectl top pods $namespace | head -20"
}