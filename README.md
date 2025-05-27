# DevOps Terminal Environment

A comprehensive terminal-based environment optimized for DevOps engineers, featuring advanced configurations for cloud platforms, container orchestration, infrastructure as code, and CI/CD workflows.

![DevOps Environment](https://img.shields.io/badge/DevOps-Terminal-blue)
![Version](https://img.shields.io/badge/Version-2.0.0-green)
![License](https://img.shields.io/badge/License-MIT-orange)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/joshuamichaelhall/devops-terminal-environment.git
cd devops-terminal-environment

# Run the migration script if coming from enhanced-terminal-environment
./migrate-from-enhanced.sh

# Or for fresh installation
./install.sh

# Start a new terminal session to load the environment
source ~/.zshrc

# Check your DevOps environment
devops_info
```

## Features

- **Cloud Platform Integration**: AWS, Azure, GCP CLI configurations and helpers
- **Kubernetes Management**: kubectl aliases, context switching, and troubleshooting tools
- **Infrastructure as Code**: Terraform workspace management and validation helpers
- **Container Workflows**: Docker and docker-compose optimizations
- **CI/CD Tools**: GitHub Actions, Jenkins, GitLab CI integrations
- **Monitoring Stack**: Prometheus, Grafana, and observability tool configurations
- **Security Tools**: DevSecOps scanning and secrets management
- **Learning Path**: 12-month structured DevOps curriculum

## DevOps Tool Support

### Container & Orchestration
- **Container Platforms**: Docker, Podman, containerd
- **Orchestration**: Kubernetes, Helm, Kustomize, ArgoCD
- **Service Mesh**: Istio, Linkerd configurations

### Infrastructure as Code
- **IaC Tools**: Terraform, OpenTofu, CloudFormation
- **Configuration Management**: Ansible, Chef, Puppet basics
- **GitOps**: Flux, ArgoCD workflows

### CI/CD & Automation
- **CI/CD**: GitHub Actions, GitLab CI, Jenkins, CircleCI
- **Build Tools**: Make, Gradle, Maven configurations
- **Artifact Management**: Nexus, Artifactory configs

### Monitoring & Observability
- **Metrics**: Prometheus, Grafana, CloudWatch
- **Logging**: ELK Stack, Fluentd, CloudTrail
- **Tracing**: Jaeger, Zipkin, X-Ray

### Cloud Platforms
- **AWS**: CLI v2, SSO, profile management
- **Azure**: Azure CLI, cloud shell integration
- **GCP**: gcloud SDK, kubectl for GKE

## Learning Path

The 12-month DevOps learning path is structured for progressive skill development:

### Foundations (Months 1-5)
- **Month 1:** [Terminal & Shell Fundamentals](learning_guides/month-01-terminal-fundamentals.md)
- **Month 2:** [Vim, Neovim & Text Editing](learning_guides/month-02-vim-neovim.md)
- **Month 3:** [Tmux & Session Management](learning_guides/month-03-tmux-session.md)
- **Month 4:** [Shell Scripting & Automation](learning_guides/month-04-shell-scripting.md)
- **Month 5:** [Git & Version Control Mastery](learning_guides/month-05-git-version-control.md)

### DevOps Core (Months 6-9)
- **Month 6:** [Docker & Container Fundamentals](learning_guides/month-06-docker-containers.md)
- **Month 7:** [Kubernetes Container Orchestration](learning_guides/month-07-kubernetes-orchestration.md)
- **Month 8:** [Infrastructure as Code with Terraform](learning_guides/month-08-infrastructure-as-code.md)
- **Month 9:** [CI/CD Pipeline Automation](learning_guides/month-09-cicd-automation.md)

### Advanced DevOps (Months 10-12)
- **Month 10:** [Monitoring & Observability](learning_guides/month-10-monitoring-observability.md)
- **Month 11:** [Cloud Platform Mastery](learning_guides/month-11-cloud-platform-mastery.md)
- **Month 12:** [Security, Compliance & SRE](learning_guides/month-12-security-compliance-sre.md)

## Key Commands & Functions

### AWS Management
- `aws_profile [profile]` - Switch AWS profiles with SSO support
- `aws_login [profile]` - Quick AWS SSO login
- `aws_resources` - List all AWS resources in current region
- `aws_cost_estimate [days]` - Get AWS cost breakdown

### Kubernetes Operations
- `kctx [context]` - Switch Kubernetes contexts
- `kn [namespace]` - Switch namespaces
- `kexec <pod> [command]` - Exec into pods easily
- `kall [namespace]` - Get all resources in namespace
- `port_forward <service> [port]` - Quick port forwarding

### Terraform Workflows
- `tf_workspace [name]` - Manage Terraform workspaces
- `tf_apply` - Plan and apply with confirmation
- `validate_infra` - Validate all infrastructure code

### Container Management
- `docker_clean` - Clean all Docker resources
- `dexec [container]` - Quick container shell access

### CI/CD Helpers
- `gh_pr_create <title>` - Create PR with conventional commits
- `gh_watch_runs` - Monitor GitHub Actions runs
- `validate_ci <file>` - Validate CI configuration files

### Monitoring Tools
- `prom_port_forward` - Access Prometheus locally
- `grafana_port_forward` - Access Grafana locally
- `watch_resources` - Monitor Kubernetes resources

## Installation

### Prerequisites
- macOS or Linux (Ubuntu/Debian)
- Git
- curl or wget
- sudo access (for some installations)

### Fresh Installation
```bash
git clone https://github.com/joshuamichaelhall/devops-terminal-environment.git
cd devops-terminal-environment
./install.sh
```

### Migration from enhanced-terminal-environment
```bash
cd devops-terminal-environment
./migrate-from-enhanced.sh
```

## Project Structure

```
devops-terminal-environment/
├── configs/
│   ├── kubernetes/      # K8s configurations
│   ├── helm/           # Helm configurations
│   ├── argocd/         # ArgoCD utilities
│   ├── monitoring/     # Prometheus/Grafana
│   ├── cicd/          # CI/CD tool configs
│   ├── docker/        # Container configs
│   ├── git/           # Git configurations
│   ├── neovim/        # Editor setup
│   ├── tmux/          # Multiplexer config
│   └── zsh/           # Shell config
├── scripts/
│   ├── devops/        # DevOps utilities
│   ├── setup/         # Installation scripts
│   └── utils/         # Helper utilities
├── learning_guides/   # 12-month curriculum
├── docs/             # Documentation
└── examples/         # Example projects
```

## Troubleshooting

### Common Issues

1. **Tool not found errors**
   ```bash
   # Install missing DevOps tools
   brew install kubectl helm terraform aws-cli
   ```

2. **Permission issues**
   ```bash
   chmod +x scripts/**/*.sh
   ```

3. **Configuration conflicts**
   ```bash
   # Backup existing configs
   ./migrate-from-enhanced.sh
   ```

### Getting Help

- Run `devops_info` to check environment status
- Check installation log: `install_log.txt`
- Use `./verify.sh` to validate setup
- Open issues on GitHub for support

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE.md) for details.

## Acknowledgments

- Built on foundations from enhanced-terminal-environment
- Incorporates best practices from the DevOps community
- Developed with assistance from Anthropic's Claude AI

---

> "Infrastructure as Code is not just about automation, it's about bringing software engineering practices to infrastructure management." - Kief Morris