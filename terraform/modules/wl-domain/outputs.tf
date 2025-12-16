# terraform/modules/wl-domain/outputs.tf

output "zone_id" {
  description = "Cloudflare Zone ID"
  value       = local.zone_id
}

output "regional_certificate_arn" {
  description = "Regional certificate ARN"
  value       = module.validation.regional_certificate_arn
}

output "cloudfront_certificate_arn" {
  description = "CloudFront certificate ARN"
  value       = module.validation.cloudfront_certificate_arn
}

output "admin" {
  description = "Admin distribution details"
  value = var.create_admin ? {
    fqdn               = module.admin[0].fqdn
    s3_bucket          = module.admin[0].s3_bucket_name
    cloudfront_domain  = module.admin[0].cloudfront_domain_name
    cloudfront_id      = module.admin[0].cloudfront_distribution_id
  } : null
}

output "agent" {
  description = "Agent distribution details"
  value = var.create_agent ? {
    fqdn               = module.agent[0].fqdn
    s3_bucket          = module.agent[0].s3_bucket_name
    cloudfront_domain  = module.agent[0].cloudfront_domain_name
    cloudfront_id      = module.agent[0].cloudfront_distribution_id
  } : null
}

output "click" {
  description = "Click distribution details"
  value = var.create_click ? {
    fqdn               = module.click[0].fqdn
    s3_bucket          = module.click[0].s3_bucket_name
    cloudfront_domain  = module.click[0].cloudfront_domain_name
    cloudfront_id      = module.click[0].cloudfront_distribution_id
  } : null
}

output "cdn" {
  description = "CDN distribution details"
  value = var.create_cdn ? {
    fqdn               = module.cdn[0].fqdn
    s3_bucket          = module.cdn[0].s3_bucket_name
    cloudfront_domain  = module.cdn[0].cloudfront_domain_name
    cloudfront_id      = module.cdn[0].cloudfront_distribution_id
  } : null
}

output "reports" {
  description = "Reports distribution details"
  value = var.create_reports ? {
    fqdn               = module.reports[0].fqdn
    s3_bucket          = module.reports[0].s3_bucket_name
    cloudfront_domain  = module.reports[0].cloudfront_domain_name
    cloudfront_id      = module.reports[0].cloudfront_distribution_id
  } : null
}

# ============================================================================
# ALB DNS Outputs
# ============================================================================

output "api_dns_record" {
  description = "API DNS record details"
  value = var.create_api_record ? {
    fqdn    = "api.${var.domain}"
    target  = var.alb_dns_name
    proxied = true
  } : null
}

output "root_alb_dns_record" {
  description = "Root domain ALB DNS record (for click domains)"
  value = var.create_root_record ? {
    fqdn    = var.domain
    target  = var.alb_dns_name
    proxied = true
  } : null
}