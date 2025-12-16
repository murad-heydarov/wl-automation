# terraform/modules/mailgun/versions.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    mailgun = {
      source  = "murad-heydarov/mailgun"
      version = "0.1.5"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}