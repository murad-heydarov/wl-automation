# terraform/modules/mailgun/variables.tf

variable "domain" {
  description = "Main domain (e.g., afftech.xyz)"
  type        = string
}

variable "mail_domain" {
  description = "Mail domain (e.g., support.afftech.xyz)"
  type        = string
}

variable "mailgun_region" {
  description = "Mailgun region (us or eu)"
  type        = string
  default     = "eu"

  validation {
    condition     = contains(["us", "eu"], var.mailgun_region)
    error_message = "Mailgun region must be 'us' or 'eu'."
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for DNS records"
  type        = string

  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.cloudflare_zone_id))
    error_message = "Cloudflare Zone ID must be 32 hexadecimal characters."
  }
}

variable "smtp_login" {
  description = "SMTP login username (will be @mail_domain)"
  type        = string
  default     = "postmaster"
}

variable "wait_for_verification" {
  description = "Wait for domain verification to complete"
  type        = bool
  default     = true
}

variable "verification_poll_interval" {
  description = "How often to check verification status"
  type        = string
  default     = "15s"
}

variable "verification_timeout" {
  description = "Maximum time to wait for verification"
  type        = string
  default     = "10m"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "spam_action" { default = "disabled" }
variable "wildcard" { default = false }
variable "open_tracking" { default = false }
variable "click_tracking" { default = false }
variable "web_scheme" { default = "https" }