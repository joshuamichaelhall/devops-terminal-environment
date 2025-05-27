#!/usr/bin/env zsh
# Kubernetes/kubectl configuration and utilities

# kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgi='kubectl get ingress'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kgaa='kubectl get all -A'

# Describe resources
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'

# Logs
alias kl='kubectl logs'
alias klf='kubectl logs -f'

# Apply/Delete
alias ka='kubectl apply -f'
alias kd='kubectl delete -f'

# Context and namespace management
alias kctx='kubectl config get-contexts'
alias kns='kubectl get namespaces'
alias kuse='kubectl config use-context'

# Function to switch namespace
kn() {
    if [[ -z "$1" ]]; then
        echo "Current namespace: $(kubectl config view --minify -o jsonpath='{..namespace}')"
    else
        kubectl config set-context --current --namespace="$1"
        echo "Switched to namespace: $1"
    fi
}

# Function to get all resources in a namespace
kall() {
    local namespace="${1:-default}"
    kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n "$namespace"
}

# Function to decode secret
kdecode() {
    kubectl get secret "$1" -o jsonpath="{.data.$2}" | base64 -d
}

# Function to exec into pod
kexec() {
    local pod="$1"
    shift
    kubectl exec -it "$pod" -- "${@:-/bin/bash}"
}

# Function to port-forward
kpf() {
    local resource="$1"
    local ports="$2"
    kubectl port-forward "$resource" "$ports"
}

# Kubernetes prompt info for PS1 (optional)
kube_ps1() {
    local context=$(kubectl config current-context 2>/dev/null)
    local namespace=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
    
    if [[ -n "$context" ]]; then
        echo " ☸️  ${context}:${namespace:-default}"
    fi
}

# Enable kubectl autocompletion
if command -v kubectl &> /dev/null; then
    source <(kubectl completion zsh)
fi