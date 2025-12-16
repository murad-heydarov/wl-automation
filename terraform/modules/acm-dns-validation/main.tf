# terraform/modules/acm-dns-validation/main.tf

# ============================================================================
# Locals: Extract and Deduplicate Validation Records
# ============================================================================

locals {
  # Extract regional validation records
  regional_groups = var.regional_certificate != null ? {
    for dvo in var.regional_certificate.domain_validation_options :
    trimsuffix(dvo.resource_record_name, ".") => {
      name    = trimsuffix(dvo.resource_record_name, ".")
      content = trimsuffix(dvo.resource_record_value, ".")
      type    = dvo.resource_record_type
      domain  = dvo.domain_name
      source  = "regional"
    }...
  } : {}

  regional_records = {
    for k, v in local.regional_groups :
    k => v[length(v) - 1]
  }

  cloudfront_groups = var.cloudfront_certificate != null ? {
    for dvo in var.cloudfront_certificate.domain_validation_options :
    trimsuffix(dvo.resource_record_name, ".") => {
      name    = trimsuffix(dvo.resource_record_name, ".")
      content = trimsuffix(dvo.resource_record_value, ".")
      type    = dvo.resource_record_type
      domain  = dvo.domain_name
      source  = "cloudfront"
    }...
  } : {}

  cloudfront_records = {
    for k, v in local.cloudfront_groups :
    k => v[length(v) - 1]
  }

  all_validation_records = merge(
    local.regional_records,
    local.cloudfront_records
  )
}

# ============================================================================
# Cloudflare DNS Validation Records
# Creates deduplicated CNAME records for ACM validation
# ============================================================================

resource "cloudflare_dns_record" "validation" {
  for_each = local.all_validation_records

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  ttl     = 1
  proxied = false

  comment = "ACM validation - ${each.value.domain} (${each.value.source})"

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Certificate Validation Wait
# Waits for AWS to validate certificates via DNS
# ============================================================================

resource "aws_acm_certificate_validation" "regional" {
  count = var.regional_certificate != null ? 1 : 0

  certificate_arn = var.regional_certificate.arn
  validation_record_fqdns = [
    for rec in cloudflare_dns_record.validation : rec.name
  ]

  timeouts {
    create = var.validation_timeout
  }

  depends_on = [cloudflare_dns_record.validation]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  count    = var.cloudfront_certificate != null ? 1 : 0
  provider = aws.east

  certificate_arn = var.cloudfront_certificate.arn

  validation_record_fqdns = [
    for rec in cloudflare_dns_record.validation : rec.name
  ]

  timeouts {
    create = var.validation_timeout
  }

  depends_on = [cloudflare_dns_record.validation]
}
