# terraform/modules/mailgun/outputs.tf

# ============================================================================
# Domain Outputs
# ============================================================================

output "domain_name" {
  description = "Mailgun domain name"
  value       = mailgun_domain.wl.name
}

output "domain_region" {
  description = "Mailgun domain region"
  value       = mailgun_domain.wl.region
}

# ============================================================================
# SMTP Outputs
# ============================================================================

output "smtp_login" {
  description = "Full SMTP login email (e.g., postmaster@support.domain.com)"
  value       = mailgun_domain.wl.smtp_login
}

output "smtp_password" {
  description = "SMTP password (sensitive)"
  value       = random_password.smtp.result
  sensitive   = true
}

output "smtp_credential_email" {
  description = "SMTP credential email address"
  value       = "${var.smtp_login}@${var.mail_domain}"
}

# ============================================================================
# Verification Outputs
# ============================================================================

output "verification_status" {
  description = "Domain verification status (e.g., active, unverified)"
  value       = mailgun_domain_verification.wl.status
}

output "use_automatic_sender_security" {
  description = "Whether automatic sender security is enabled"
  value       = mailgun_domain.wl.use_automatic_sender_security
}

# ============================================================================
# DNS Records Outputs
# ============================================================================

output "sending_records" {
  description = "Mailgun sending DNS records (SPF, DKIM)"
  value       = mailgun_domain.wl.sending_records_set
}

output "receiving_records" {
  description = "Mailgun receiving DNS records (MX)"
  value       = mailgun_domain.wl.receiving_records_set
}

# ============================================================================
# Summary Output
# ============================================================================

output "mailgun_summary" {
  description = "Complete Mailgun configuration summary"
  value = {
    domain                        = mailgun_domain.wl.name
    region                        = mailgun_domain.wl.region
    smtp_login                    = mailgun_domain.wl.smtp_login
    verification_status           = mailgun_domain_verification.wl.status
    use_automatic_sender_security = mailgun_domain.wl.use_automatic_sender_security
  }
}