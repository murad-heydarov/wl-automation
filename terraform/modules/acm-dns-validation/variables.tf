# terraform/modules/acm-dns-validation/variables.tf

variable "domain_name" {
  description = "Domain name being validated"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID where DNS records will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.cloudflare_zone_id))
    error_message = "Cloudflare Zone ID must be 32 hexadecimal characters."
  }
}

variable "regional_certificate" {
  description = "Regional certificate object from acm-certificates module"
  type = object({
    id          = string
    arn         = string
    domain_name = string
    status      = string
    domain_validation_options = set(object({
      domain_name           = string
      resource_record_name  = string
      resource_record_type  = string
      resource_record_value = string
    }))
  })
  default = null
}

variable "cloudfront_certificate" {
  description = "CloudFront certificate object from acm-certificates module"
  type = object({
    id          = string
    arn         = string
    domain_name = string
    status      = string
    domain_validation_options = set(object({
      domain_name           = string
      resource_record_name  = string
      resource_record_type  = string
      resource_record_value = string
    }))
  })
  default = null
}

variable "validation_timeout" {
  description = "Maximum time to wait for certificate validation"
  type        = string
  default     = "45m"

  validation {
    condition     = can(regex("^[0-9]+(m|h)$", var.validation_timeout))
    error_message = "Timeout must be in format like '45m' or '1h'."
  }
}