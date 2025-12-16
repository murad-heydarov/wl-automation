# terraform/environments/prod/providers.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
    mailgun = {
      source  = "murad-heydarov/mailgun"
      version = "0.1.5"
    }
  }
}

# Default AWS Provider (eu-central-1)
provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Project     = "WL-Automation"
      ManagedBy   = "Terraform"
      Environment = "production"
    }
  }
}

# AWS Provider for us-east-1 (CloudFront requirement)
provider "aws" {
  alias  = "east"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "WL-Automation"
      ManagedBy   = "Terraform"
      Environment = "production"
    }
  }
}

# Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# GitLab Provider
provider "gitlab" {
  token    = var.gitlab_token
  base_url = var.gitlab_base_url
}

# Mailgun Provider
provider "mailgun" {
  api_key = var.mailgun_api_key
}
