# WL Configuration Guide

This directory contains White Label (WL) configurations for automated infrastructure deployment.

## Quick Start

1. **Choose your WL type** (agent, click, or mixed)
2. **Copy the appropriate template** from `templates/` directory
3. **Fill in your values** from Confluence
4. **Deploy** using Terraform

## Available Templates

- [`templates/agent-wl.auto.tfvars.template`](templates/agent-wl.auto.tfvars.template) - For Agent WLs (Admin + Agent panels)
- [`templates/click-wl.auto.tfvars.template`](templates/click-wl.auto.tfvars.template) - For Click WLs (Admin panel only)
- [`templates/mixed-wl.auto.tfvars.template`](templates/mixed-wl.auto.tfvars.template) - For Mixed WLs (Admin + Agent + Click)

## How to Use Templates

### Step 1: Copy Template
```bash
# Example: Creating config for a new Agent WL called "newwl"
cd terraform/environments/prod/wl-configs
cp templates/agent-wl.auto.tfvars.template newwl.auto.tfvars
```

### Step 2: Fill in Values

Open `newwl.auto.tfvars` and fill in your values from Confluence:
```hcl
domain             = "newwl.com"        # From Confluence: Main domain
wl_type            = "agent"            # Keep as-is from template
platform_code      = "NEWWL"            # From Confluence: Platform code
cloudflare_zone_id = "abc123..."        # From Cloudflare dashboard

admin_subdomain = "admin"               # From Confluence: Admin Domain subdomain
agent_subdomain = "agent"               # From Confluence: Agent Domain subdomain

gitlab_project_id = "marketingtech/wl-automation"
```

### Step 3: Deploy
```bash
cd terraform/environments/prod
terraform plan -var-file="wl-configs/newwl.auto.tfvars"
terraform apply -var-file="wl-configs/newwl.auto.tfvars"
```

## WL Type Decision Guide

### When to use AGENT WL?
- WL has Admin panel + Agent panel
- May or may not have a separate click domain
- Example: Liravegas

### When to use CLICK WL?
- WL has Admin panel only (no agent panel)
- Typically has a separate click domain for tracking
- Example: Slapkong Partners

### When to use MIXED WL?
- WL has Admin panel + Agent panel + Click on main domain (root)
- May also have an additional separate click domain
- Example: Owinbet

## Confluence Mapping

| Confluence Field | Config Variable | Example |
|-----------------|-----------------|---------|
| WL Name | (not used) | "Liravegas" |
| Platform code | `platform_code` | "LIRV" |
| Main domain | `domain` | "liravegas.com" |
| Admin Domain | `admin_subdomain` | "admin" (from "admin.liravegas.com") |
| Agent Domain | `agent_subdomain` | "agent" (from "agent.liravegas.com") |
| Click-domain | `click_domain` | "trackinglira.com" |

## What Gets Created?

### Agent WL Resources
- ACM Certificates (regional + CloudFront)
- S3 Buckets + CloudFront Distributions:
  - `admin.domain.com`
  - `agent.domain.com`
  - `cdn.domain.com`
  - `reports.domain.com`
- Cloudflare DNS records
- GitLab CI/CD variables:
  - `PLATFORM_CODE_PROD_BUCKET_NAME`
  - `PLATFORM_CODE_AGENT_PROD_BUCKET_NAME`

### Click WL Resources
- ACM Certificates (regional + CloudFront)
- S3 Buckets + CloudFront Distributions:
  - `admin.domain.com`
  - `cdn.domain.com`
  - `reports.domain.com`
- Cloudflare DNS records
- GitLab CI/CD variables:
  - `PLATFORM_CODE_PROD_BUCKET_NAME`

### Mixed WL Resources
- ACM Certificates (regional + CloudFront)
- S3 Buckets + CloudFront Distributions:
  - `admin.domain.com`
  - `agent.domain.com`
  - `domain.com` (root domain for click)
  - `cdn.domain.com`
  - `reports.domain.com`
- Cloudflare DNS records
- GitLab CI/CD variables:
  - `PLATFORM_CODE_PROD_BUCKET_NAME`
  - `PLATFORM_CODE_AGENT_PROD_BUCKET_NAME`

## Troubleshooting

See [TROUBLESHOOTING.md](../../../docs/TROUBLESHOOTING.md) for common issues and solutions.

## Examples

- [`afftech.auto.tfvars`](afftech.auto.tfvars) - Agent WL example
- [`brandx.auto.tfvars`](brandx.auto.tfvars) - Click WL example
- [`owinbet.auto.tfvars`](owinbet.auto.tfvars) - Mixed WL example