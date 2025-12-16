# terraform/modules/acm-certificates/variables.tf

variable "domain_name" {
  description = "Primary domain name for ACM certificate (e.g., 'afftech.xyz')"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be valid format (e.g., 'example.com')."
  }
}

variable "subject_alternative_names" {
  description = "Subject Alternative Names (e.g., ['*.example.com'])"
  type        = list(string)
  default     = []
}

variable "create_regional_cert" {
  description = "Create regional certificate (eu-central-1)"
  type        = bool
  default     = true
}

variable "create_cloudfront_cert" {
  description = "Create CloudFront certificate (us-east-1)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for certificates"
  type        = map(string)
  default     = {}
}