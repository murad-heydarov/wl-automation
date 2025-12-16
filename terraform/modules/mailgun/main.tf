# terraform/modules/mailgun/main.tf

# ============================================================================
# Random SMTP Password Generation
# ============================================================================
resource "random_password" "smtp" {
  length  = 16
  special = false
}

# ============================================================================
# Mailgun Domain Creation
# ============================================================================
resource "mailgun_domain" "wl" {
  name                          = var.mail_domain
  region                        = var.mailgun_region
  spam_action                   = var.spam_action
  wildcard                      = var.wildcard
  use_automatic_sender_security = true

  open_tracking  = var.open_tracking
  click_tracking = var.click_tracking
  web_scheme     = var.web_scheme
}

# ============================================================================
# SMTP Credential Creation
# ============================================================================
resource "mailgun_domain_credential" "smtp_user" {
  domain   = mailgun_domain.wl.name
  login    = var.smtp_login
  password = random_password.smtp.result
  region   = var.mailgun_region

  lifecycle {
    ignore_changes = [password]
  }

  depends_on = [mailgun_domain.wl]
}

# ============================================================================
# DNS Records - Cloudflare Integration
# ============================================================================

# MX Records (Receiving) - use record.id as key (unique: mxa, mxb)
resource "cloudflare_dns_record" "mailgun_mx" {
  for_each = {
    for record in mailgun_domain.wl.receiving_records_set :
    record.id => record
    if record.record_type == "MX"
  }

  zone_id  = var.cloudflare_zone_id
  name     = var.mail_domain
  type     = "MX"
  content  = each.value.value
  priority = tonumber(each.value.priority)
  ttl      = 1
  proxied  = false
  comment  = "Mailgun MX - ${var.domain}"
}

# TXT/SPF Records (Sending) - use record.name as key (unique)
resource "cloudflare_dns_record" "mailgun_txt" {
  for_each = {
    for record in mailgun_domain.wl.sending_records_set :
    record.name => record
    if record.record_type == "TXT"
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = "TXT"
  content = "\"${each.value.value}\"" 
  ttl     = 1
  proxied = false
  comment = "Mailgun SPF - ${var.domain}"
}


# DKIM/CNAME Records (Sending) - use record.name as key (unique!)
resource "cloudflare_dns_record" "mailgun_cname" {
  for_each = {
    for record in mailgun_domain.wl.sending_records_set :
    record.name => record
    if record.record_type == "CNAME"
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = "CNAME"
  content = each.value.value
  ttl     = 1
  proxied = false
  comment = "Mailgun DKIM - ${var.domain}"
}

# ============================================================================
# Automatic Domain Verification
# ============================================================================
resource "mailgun_domain_verification" "wl" {
  domain          = mailgun_domain.wl.name
  region          = var.mailgun_region
  wait_for_active = var.wait_for_verification
  poll_interval   = var.verification_poll_interval
  timeout         = var.verification_timeout

  depends_on = [
    mailgun_domain.wl,
    cloudflare_dns_record.mailgun_mx,
    cloudflare_dns_record.mailgun_txt,
    cloudflare_dns_record.mailgun_cname
  ]
}