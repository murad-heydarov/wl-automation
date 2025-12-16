# terraform/modules/cloudfront-s3-website/variables.tf

# ============================================================================
# Core Configuration
# ============================================================================

variable "domain_name" {
  description = "Primary domain name (e.g., 'afftech.xyz')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain must be valid format (e.g., 'example.com')."
  }
}

variable "subdomain" {
  description = "Subdomain prefix (e.g., 'admin' for admin.afftech.xyz) or '@' for root domain"
  type        = string

  validation {
    condition     = can(regex("^(@|[a-z0-9-]+)$", var.subdomain))
    error_message = "Subdomain must contain only lowercase letters, numbers, hyphens, or '@' for root domain."
  }
}

variable "certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1 for CloudFront)"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:acm:us-east-1:[0-9]{12}:certificate/[a-f0-9-]+$", var.certificate_arn))
    error_message = "Certificate ARN must be valid us-east-1 ACM certificate."
  }
}

# ============================================================================
# S3 Configuration
# ============================================================================

variable "s3_index_document" {
  description = "S3 website index document"
  type        = string
  default     = "index.html"
}

variable "s3_error_document" {
  description = "S3 website error document"
  type        = string
  default     = "index.html"
}

variable "enable_versioning" {
  description = "Enable S3 versioning"
  type        = bool
  default     = false
}

# ============================================================================
# CloudFront Configuration
# ============================================================================

variable "enable_compression" {
  description = "Enable CloudFront compression"
  type        = bool
  default     = true
}

variable "viewer_protocol_policy" {
  description = "Viewer protocol policy"
  type        = string
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "Must be 'allow-all', 'https-only', or 'redirect-to-https'."
  }
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_All"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Must be valid price class."
  }
}

variable "min_ttl" {
  description = "Minimum TTL for CloudFront cache"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL for CloudFront cache"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum TTL for CloudFront cache"
  type        = number
  default     = 86400
}

variable "custom_error_responses" {
  description = "Custom error responses for CloudFront"
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

# ============================================================================
# Tags
# ============================================================================

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# ============================================================================
# OAC Configuration
# ============================================================================

variable "oac_name" {
  description = "Custom name for CloudFront Origin Access Control (leave empty to autogenerate)"
  type        = string
  default     = ""
}
