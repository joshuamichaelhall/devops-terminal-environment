#!/usr/bin/env zsh
# CI/CD tools configuration (GitHub Actions, Jenkins, GitLab CI)

# GitHub CLI aliases
alias gh='gh'
alias ghpr='gh pr'
alias ghprlist='gh pr list'
alias ghprcreate='gh pr create'
alias ghprview='gh pr view'
alias ghprcheck='gh pr checks'
alias ghworkflow='gh workflow'
alias ghrun='gh run'
alias ghrunlist='gh run list'
alias ghrunview='gh run view'
alias ghrunwatch='gh run watch'

# Function to create PR with conventional commit
gh_pr_create() {
    local title="$1"
    local body="${2:-}"
    
    gh pr create --title "$title" --body "$body" --assignee @me
}

# Function to watch workflow runs
gh_watch_runs() {
    watch -n 5 'gh run list --limit 10'
}

# Function to trigger workflow manually
gh_trigger_workflow() {
    local workflow="$1"
    local branch="${2:-main}"
    
    gh workflow run "$workflow" --ref "$branch"
}

# Jenkins CLI helpers (requires jenkins-cli.jar)
jenkins_cli() {
    local jenkins_url="${JENKINS_URL:-http://localhost:8080}"
    local cmd="$1"
    shift
    
    java -jar ~/bin/jenkins-cli.jar -s "$jenkins_url" "$cmd" "$@"
}

# Function to trigger Jenkins job
jenkins_build() {
    local job="$1"
    shift
    jenkins_cli build "$job" "$@"
}

# Function to get Jenkins job status
jenkins_status() {
    local job="$1"
    jenkins_cli get-job "$job" | grep '<color>' | sed 's/.*<color>\(.*\)<\/color>.*/\1/'
}

# GitLab CI helpers
gitlab_pipeline_status() {
    local project="${1:-$CI_PROJECT_ID}"
    glab pipeline list --project-id "$project"
}

# Function to validate CI config files
validate_ci() {
    local ci_file="$1"
    
    case "$ci_file" in
        *.gitlab-ci.yml|.gitlab-ci.yml)
            echo "Validating GitLab CI config..."
            glab ci validate "$ci_file"
            ;;
        .github/workflows/*.yml|.github/workflows/*.yaml)
            echo "Validating GitHub Actions workflow..."
            # GitHub doesn't have a CLI validator, but we can check YAML syntax
            yq eval '.' "$ci_file" > /dev/null && echo "✓ Valid YAML syntax"
            ;;
        Jenkinsfile)
            echo "Validating Jenkinsfile..."
            # Basic syntax check for Jenkinsfile
            groovy -c "new File('$ci_file').text" 2>&1 | grep -q "error" && echo "✗ Syntax errors found" || echo "✓ Valid Groovy syntax"
            ;;
        *)
            echo "Unknown CI config file type"
            ;;
    esac
}

# Docker build helpers for CI
docker_build_ci() {
    local tag="$1"
    local dockerfile="${2:-Dockerfile}"
    local context="${3:-.}"
    
    docker build \
        --cache-from "${tag}:latest" \
        --tag "${tag}:${CI_COMMIT_SHA:-latest}" \
        --tag "${tag}:latest" \
        --file "$dockerfile" \
        "$context"
}

# Function to setup CI secrets in local environment
setup_ci_secrets() {
    echo "Setting up CI secrets for local testing..."
    
    # GitHub Actions
    if [[ -d .github ]]; then
        echo "GitHub Actions detected. Use 'act' for local testing:"
        echo "  brew install act"
        echo "  act -s GITHUB_TOKEN=\$(gh auth token)"
    fi
    
    # GitLab CI
    if [[ -f .gitlab-ci.yml ]]; then
        echo "GitLab CI detected. Use 'gitlab-runner' for local testing:"
        echo "  brew install gitlab-runner"
        echo "  gitlab-runner exec docker <job_name>"
    fi
}

# Aliases for common CI/CD tasks
alias ci-lint='find . -name "*.yml" -o -name "*.yaml" | xargs yamllint'
alias ci-validate='validate_ci'
alias ci-secrets='setup_ci_secrets'

# Function to generate basic GitHub Actions workflow
generate_github_workflow() {
    local name="${1:-ci}"
    local workflow_file=".github/workflows/${name}.yml"
    
    mkdir -p .github/workflows
    
    cat > "$workflow_file" <<'EOF'
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run tests
      run: |
        echo "Add your test commands here"
        
    - name: Build
      run: |
        echo "Add your build commands here"
EOF
    
    echo "Created workflow: $workflow_file"
}