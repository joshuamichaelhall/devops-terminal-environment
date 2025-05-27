#!/usr/bin/env zsh
# Helm configuration and utilities

# Helm aliases
alias h='helm'
alias hl='helm list'
alias hla='helm list -A'
alias hs='helm search'
alias hsr='helm search repo'
alias hsh='helm search hub'
alias hi='helm install'
alias hu='helm upgrade'
alias hd='helm delete'
alias hr='helm rollback'
alias hg='helm get'
alias hgv='helm get values'
alias hgm='helm get manifest'
alias ht='helm template'
alias hp='helm package'

# Helm repo management
alias hra='helm repo add'
alias hru='helm repo update'
alias hrl='helm repo list'
alias hrr='helm repo remove'

# Function to add common Helm repos
helm_init_repos() {
    echo "Adding common Helm repositories..."
    helm repo add stable https://charts.helm.sh/stable
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo add jetstack https://charts.jetstack.io
    helm repo add elastic https://helm.elastic.co
    helm repo add gitlab https://charts.gitlab.io
    helm repo add harbor https://helm.goharbor.io
    helm repo update
    echo "Helm repositories added and updated!"
}

# Function to search all repos
hsearch() {
    local query="$1"
    echo "=== Searching Helm Hub ==="
    helm search hub "$query" | head -10
    echo -e "\n=== Searching Local Repos ==="
    helm search repo "$query"
}

# Function to diff helm releases
hdiff() {
    local release="$1"
    local revision1="${2:-0}"
    local revision2="${3:-0}"
    
    if [[ "$revision2" -eq 0 ]]; then
        # Compare current with previous
        helm get manifest "$release" > /tmp/helm-current.yaml
        helm get manifest "$release" --revision $(($(helm history "$release" -o json | jq length)-1)) > /tmp/helm-previous.yaml
    else
        helm get manifest "$release" --revision "$revision1" > /tmp/helm-previous.yaml
        helm get manifest "$release" --revision "$revision2" > /tmp/helm-current.yaml
    fi
    
    diff -u /tmp/helm-previous.yaml /tmp/helm-current.yaml
}

# Function to test helm chart
htest() {
    local chart="$1"
    shift
    helm install --dry-run --debug test-release "$chart" "$@"
}

# Enable Helm autocompletion
if command -v helm &> /dev/null; then
    source <(helm completion zsh)
fi