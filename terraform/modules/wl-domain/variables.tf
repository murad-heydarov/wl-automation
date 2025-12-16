# terraform/modules/wl-domain/variables.tf

variable "domain" {
  description = "Domain name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]\\.[a-z]{2,}$", var.domain))
    error_message = "Domain must be valid format."
  }
}

variable "sans" {
  description = "Subject Alternative Names"
  type        = list(string)
  default     = []
}

variable "create_regional_cert" {
  description = "Create regional certificate"
  type        = bool
  default     = true
}

variable "create_cloudfront_cert" {
  description = "Create CloudFront certificate"
  type        = bool
  default     = true
}

variable "create_admin" {
  description = "Create admin CloudFront"
  type        = bool
  default     = true
}

variable "create_agent" {
  description = "Create agent CloudFront"
  type        = bool
  default     = false
}

variable "create_click" {
  description = "Create click subdomain CloudFront"
  type        = bool
  default     = false
}

# ============================================================================
# Subdomain Configuration (from Confluence)
# ============================================================================

variable "admin_subdomain" {
  description = "Admin subdomain (from Confluence Admin Domain field, e.g., 'admin', 'adminagent')"
  type        = string
  default     = "admin"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.admin_subdomain))
    error_message = "Admin subdomain must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "agent_subdomain" {
  description = "Agent subdomain (from Confluence Agent Domain field, e.g., 'agent')"
  type        = string
  default     = "agent"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.agent_subdomain))
    error_message = "Agent subdomain must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "validation_timeout" {
  description = "ACM validation timeout"
  type        = string
  default     = "45m"
}

variable "s3_index_document" {
  type    = string
  default = "index.html"
}

variable "s3_error_document" {
  type    = string
  default = "index.html"
}

variable "enable_versioning" {
  type    = bool
  default = false
}

variable "enable_compression" {
  type    = bool
  default = true
}

variable "viewer_protocol_policy" {
  type    = string
  default = "redirect-to-https"
}

variable "price_class" {
  type    = string
  default = "PriceClass_All"
}

variable "min_ttl" {
  type    = number
  default = 0
}

variable "default_ttl" {
  type    = number
  default = 3600
}

variable "max_ttl" {
  type    = number
  default = 86400
}

variable "custom_error_responses" {
  type = list(object({
    error_code         = number
    response_code      = number
    response_page_path = string
  }))
  default = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID (if you have multiple accounts)"
  type        = string
  default     = null
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  default     = null
}

# ============================================================================
# CDN and Reports Configuration
# ============================================================================

variable "create_cdn" {
  description = "Create CDN CloudFront distribution"
  type        = bool
  default     = true
}

variable "create_reports" {
  description = "Create Reports CloudFront distribution"
  type        = bool
  default     = true
}

variable "cdn_subdomain" {
  description = "CDN subdomain name"
  type        = string
  default     = "cdn"
}

variable "reports_subdomain" {
  description = "Reports subdomain name"
  type        = string
  default     = "reports"
}

# CDN-specific cache settings
variable "cdn_default_ttl" {
  description = "Default TTL for CDN cache (in seconds)"
  type        = number
  default     = 86400  # 24 hours
}

variable "cdn_max_ttl" {
  description = "Maximum TTL for CDN cache (in seconds)"
  type        = number
  default     = 31536000  # 1 year
}

# Reports-specific settings
variable "reports_enable_versioning" {
  description = "Enable versioning for Reports S3 bucket"
  type        = bool
  default     = true
}

variable "reports_price_class" {
  description = "CloudFront price class for Reports"
  type        = string
  default     = "PriceClass_100"  # Cheaper, reports have less traffic
}

# ============================================================================
# WL Configuration
# ============================================================================

variable "wl_type" {
  description = "WL type: agent, click, or mixed"
  type        = string
  default     = "agent"

  validation {
    condition     = contains(["agent", "click", "mixed"], var.wl_type)
    error_message = "Must be 'agent', 'click', or 'mixed'."
  }
}

variable "platform_code" {
  description = "Platform code (e.g., 'LIRV', 'SLPKNG') - REQUIRED"
  type        = string

  validation {
    condition     = var.platform_code != null && length(var.platform_code) > 0
    error_message = "platform_code is required. Example: 'LIRV', 'SLPKNG', 'AFFTECH'"
  }
}

# ============================================================================
# GitLab CI/CD Configuration
# ============================================================================

variable "gitlab_project_id" {
  description = "GitLab project ID (null to skip GitLab integration)"
  type        = string
  default     = null
}

variable "gitlab_variables_protected" {
  description = "Whether GitLab variables are protected"
  type        = bool
  default     = false
}

variable "gitlab_variables_masked" {
  description = "Whether GitLab variables are masked"
  type        = bool
  default     = false
}

variable "gitlab_environment_scope" {
  description = "GitLab environment scope"
  type        = string
  default     = "*"
}

# ============================================================================
# ALB Configuration
# ============================================================================

variable "alb_dns_name" {
  description = "ALB DNS name for API ingress"
  type        = string
  default     = "mt-apps-ingress-978b1006d8a9d559.elb.eu-central-1.amazonaws.com"
}

variable "create_api_record" {
  description = "Create api.{domain} DNS record"
  type        = bool
  default     = true
}

variable "create_root_record" {
  description = "Create {domain} (root) DNS record pointing to ALB"
  type        = bool
  default     = false
}