# WL Automation

Automated White Label deployment pipeline using Terraform.

## Overview

This project automates the end-to-end deployment of White Labels (Agent WL & Click WL) including:

- ✅ ACM Certificates (with automatic DNS validation)
- ✅ S3 + CloudFront (static hosting)
- ✅ Cloudflare DNS management
- ✅ Mailgun domain setup
- ✅ Kubernetes Ingress
- ✅ GitLab CI/CD variables

## Project Structure
```
wl-automation/
├── terraform/
│   ├── modules/          # Reusable Terraform modules
│   └── environments/     # Environment-specific configsbir ca
├── scripts/              # Helper scripts
└── docs/                 # Documentation
```

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- Cloudflare API token
- Mailgun API key
- GitLab API token
- kubectl configured (for K8s module)

## Quick Start

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed instructions.

## Modules Status

- [x] ACM Module
- [ ] CloudFront Module
- [ ] Cloudflare DNS Module
- [ ] Mailgun Module
- [ ] Kubernetes Ingress Module
- [ ] GitLab Variables Module
