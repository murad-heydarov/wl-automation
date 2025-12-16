# terraform/modules/acm-dns-validation/outputs.tf

# ============================================================================
# Validation Records Outputs
# ============================================================================

output "validation_records" {
  description = "DNS validation records created in Cloudflare"
  value = {
    for key, record in cloudflare_dns_record.validation : key => {
      name    = record.name
      content = record.content
      type    = record.type
      domain  = local.all_validation_records[key].domain
      source  = local.all_validation_records[key].source
    }
  }
}

output "validation_records_count" {
  description = "Number of unique DNS validation records created"
  value       = length(cloudflare_dns_record.validation)
}

# ============================================================================
# Validated Certificate ARNs
# ============================================================================

output "regional_certificate_arn" {
  description = "Validated regional certificate ARN (ready to use)"
  value       = var.regional_certificate != null ? aws_acm_certificate_validation.regional[0].certificate_arn : null
}

output "cloudfront_certificate_arn" {
  description = "Validated CloudFront certificate ARN (ready to use)"
  value       = var.cloudfront_certificate != null ? aws_acm_certificate_validation.cloudfront[0].certificate_arn : null
}

# ============================================================================
# Debug Information
# ============================================================================

output "deduplication_info" {
  description = "Shows how many records were deduplicated"
  value = {
    regional_records_count   = length(local.regional_records)
    cloudfront_records_count = length(local.cloudfront_records)
    total_unique_records     = length(local.all_validation_records)
    duplicates_removed       = (length(local.regional_records) + length(local.cloudfront_records)) - length(local.all_validation_records)
  }
}