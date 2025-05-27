#!/usr/bin/env bash
# DevOps-specific shell functions and utilities

# AWS Profile Management
aws_profile() {
    if [[ -z "$1" ]]; then
        echo "Current AWS Profile: ${AWS_PROFILE:-default}"
        echo "Available profiles:"
        aws configure list-profiles
    else
        export AWS_PROFILE="$1"
        echo "Switched to AWS profile: $1"
        aws sts get-caller-identity
    fi
}

# Quick AWS SSO login
aws_login() {
    local profile="${1:-$AWS_PROFILE}"
    aws sso login --profile "$profile"
}

# List all AWS resources in current region
aws_resources() {
    echo "Fetching AWS resources in region: $(aws configure get region)"
    aws resourcegroupstaggingapi get-resources --output table
}

# Terraform workspace management
tf_workspace() {
    if [[ -z "$1" ]]; then
        terraform workspace list
    else
        terraform workspace select "$1" || terraform workspace new "$1"
        echo "Switched to workspace: $1"
    fi
}

# Quick Terraform plan with auto-approve option
tf_apply() {
    terraform plan -out=tfplan
    read -p "Apply changes? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply tfplan
    fi
    rm -f tfplan
}

# Container management helpers
docker_clean() {
    echo "Cleaning Docker resources..."
    docker system prune -af --volumes
    docker network prune -f
    echo "Docker cleanup complete!"
}

# Quick container shell access
dexec() {
    local container="${1:-$(docker ps -q | head -1)}"
    shift
    docker exec -it "$container" "${@:-/bin/sh}"
}

# Kubernetes context switching with namespace
kctx() {
    if [[ -z "$1" ]]; then
        kubectl config get-contexts
    else
        kubectl config use-context "$1"
        echo "Switched to context: $1"
        [[ -n "$2" ]] && kn "$2"
    fi
}

# Quick pod logs with grep
klogs() {
    local pod="$1"
    local grep_pattern="$2"
    
    if [[ -n "$grep_pattern" ]]; then
        kubectl logs -f "$pod" | grep --color=auto "$grep_pattern"
    else
        kubectl logs -f "$pod"
    fi
}

# Port forwarding helper
port_forward() {
    local service="$1"
    local port="${2:-8080}"
    local namespace="${3:-default}"
    
    echo "Port forwarding $service:$port from namespace $namespace..."
    kubectl port-forward -n "$namespace" "svc/$service" "$port" &
    echo "Service available at http://localhost:$port"
    echo "PID: $! (use 'kill $!' to stop)"
}

# Git branch cleanup
git_cleanup() {
    echo "Cleaning up merged branches..."
    git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
    echo "Pruning remote branches..."
    git remote prune origin
}

# Quick commit with conventional format
gcommit() {
    local type="$1"
    local message="$2"
    
    if [[ -z "$type" || -z "$message" ]]; then
        echo "Usage: gcommit <type> <message>"
        echo "Types: feat, fix, docs, style, refactor, test, chore"
        return 1
    fi
    
    git add -A && git commit -m "${type}: ${message}"
}

# Infrastructure validation
validate_infra() {
    echo "=== Terraform Validation ==="
    terraform fmt -check && terraform validate
    
    echo -e "\n=== Kubernetes Manifests ==="
    find . -name "*.yaml" -o -name "*.yml" | grep -E "(k8s|kubernetes)" | xargs kubectl apply --dry-run=client -f
    
    echo -e "\n=== Docker Builds ==="
    find . -name "Dockerfile*" | xargs -I {} docker build -f {} . --no-cache --check
}

# Quick environment info
devops_info() {
    echo "=== DevOps Environment Info ==="
    echo "AWS Profile: ${AWS_PROFILE:-not set}"
    echo "Kubernetes Context: $(kubectl config current-context 2>/dev/null || echo 'not set')"
    echo "Terraform Workspace: $(terraform workspace show 2>/dev/null || echo 'not initialized')"
    echo "Docker: $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 'not running')"
    echo "Git Branch: $(git branch --show-current 2>/dev/null || echo 'not in repo')"
}

# SSH key management for different environments
ssh_env() {
    local env="$1"
    local key_path="$HOME/.ssh/id_rsa_${env}"
    
    if [[ -f "$key_path" ]]; then
        ssh-add -D
        ssh-add "$key_path"
        echo "Loaded SSH key for environment: $env"
    else
        echo "SSH key not found: $key_path"
    fi
}

# Cost estimation for AWS resources
aws_cost_estimate() {
    local days="${1:-7}"
    aws ce get-cost-and-usage \
        --time-period Start=$(date -u -d "$days days ago" +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
        --granularity DAILY \
        --metrics "UnblendedCost" \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output table
}

# Aliases for quick access
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'

alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dim='docker images'

alias k='kubectl'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'

# Export functions
export -f aws_profile aws_login tf_workspace kctx devops_info