# terraform/environments/prod/variables.tf

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  default     = null
}

variable "domain" {
  description = "Primary domain"
  type        = string
  default     = null
}

variable "sans" {
  description = "Subject Alternative Names"
  type        = list(string)
  default     = null
}

variable "wl_type" {
  description = "WL type: agent, click, or mixed"
  type        = string
  default     = "agent"

  validation {
    condition     = contains(["agent", "click", "mixed"], var.wl_type)
    error_message = "Must be agent, click, or mixed."
  }
}

variable "click_domain" {
  description = "Click domain for separate click domain (root domain only)"
  type        = string
  default     = null
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  default     = null
}

variable "click_zone_id" {
  description = "Cloudflare Zone ID for click domain"
  type        = string
  default     = null
}

variable "platform_code" {
  description = "Platform code (e.g., 'LIRV', 'AFFTECH') - REQUIRED"
  type        = string

  validation {
    condition     = var.platform_code != null && length(var.platform_code) > 0
    error_message = "platform_code is required. Example: 'LIRV', 'SLPKNG', 'AFFTECH'"
  }
}

# ============================================================================
# Subdomain Configuration
# ============================================================================

variable "admin_subdomain" {
  description = "Admin subdomain (from Confluence Admin Domain)"
  type        = string
  default     = "admin"
}

variable "agent_subdomain" {
  description = "Agent subdomain (from Confluence Agent Domain)"
  type        = string
  default     = "agent"
}

# ============================================================================
# GitLab Configuration
# ============================================================================

variable "gitlab_token" {
  description = "GitLab API token (required for GitLab integration)"
  type        = string
  sensitive   = true
  default     = null
}

variable "gitlab_base_url" {
  description = "GitLab base URL"
  type        = string
  default     = "https://git.betlab.com/api/v4"
}

variable "gitlab_project_id" {
  description = "GitLab project ID or path"
  type        = string
  default     = null
}

# ============================================================================
# ALB Configuration
# ============================================================================

variable "alb_dns_name" {
  description = "ALB DNS name for API ingress"
  type        = string
  default     = "mt-apps-ingress-978b1006d8a9d559.elb.eu-central-1.amazonaws.com"
}