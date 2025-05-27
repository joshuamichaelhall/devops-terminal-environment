#!/usr/bin/env zsh
# ArgoCD configuration and utilities

# ArgoCD CLI aliases
alias argo='argocd'
alias aglogin='argocd login'
alias agapp='argocd app'
alias agapps='argocd app list'
alias agappget='argocd app get'
alias agappsync='argocd app sync'
alias agappdelete='argocd app delete'
alias agproj='argocd proj'
alias agrepo='argocd repo'
alias agcluster='argocd cluster'

# Function to login to ArgoCD
argo_login() {
    local server="${1:-localhost:8080}"
    local username="${2:-admin}"
    
    echo "Logging into ArgoCD at $server as $username..."
    argocd login "$server" --username "$username"
}

# Function to create an application
argo_create_app() {
    local app_name="$1"
    local repo_url="$2"
    local path="${3:-.}"
    local namespace="${4:-default}"
    
    argocd app create "$app_name" \
        --repo "$repo_url" \
        --path "$path" \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace "$namespace" \
        --sync-policy automated \
        --auto-prune \
        --self-heal
}

# Function to sync all apps
argo_sync_all() {
    argocd app list -o name | xargs -I {} argocd app sync {}
}

# Function to get app details with health and sync status
argo_status() {
    local app_name="$1"
    
    if [[ -z "$app_name" ]]; then
        argocd app list
    else
        argocd app get "$app_name" --refresh
    fi
}

# Function to rollback application
argo_rollback() {
    local app_name="$1"
    local revision="${2:-0}"
    
    echo "Rolling back $app_name to revision $revision..."
    argocd app rollback "$app_name" "$revision"
}

# Function to port-forward ArgoCD server
argo_port_forward() {
    local port="${1:-8080}"
    echo "Port-forwarding ArgoCD server to localhost:$port..."
    kubectl port-forward svc/argocd-server -n argocd "$port":443 &
    echo "ArgoCD UI available at: https://localhost:$port"
}

# Function to get initial admin password
argo_get_password() {
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    echo
}

# Enable ArgoCD autocompletion
if command -v argocd &> /dev/null; then
    source <(argocd completion zsh)
fi