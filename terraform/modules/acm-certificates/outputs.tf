# terraform/modules/acm-certificates/outputs.tf

# ============================================================================
# Regional Certificate Outputs
# ============================================================================

output "regional_certificate" {
  description = "Regional certificate complete details"
  value = var.create_regional_cert ? {
    id                        = aws_acm_certificate.regional[0].id
    arn                       = aws_acm_certificate.regional[0].arn
    domain_name               = aws_acm_certificate.regional[0].domain_name
    status                    = aws_acm_certificate.regional[0].status
    domain_validation_options = aws_acm_certificate.regional[0].domain_validation_options
  } : null
}

output "regional_certificate_arn" {
  description = "Regional certificate ARN (for quick reference)"
  value       = var.create_regional_cert ? aws_acm_certificate.regional[0].arn : null
}

# ============================================================================
# CloudFront Certificate Outputs
# ============================================================================

output "cloudfront_certificate" {
  description = "CloudFront certificate complete details"
  value = var.create_cloudfront_cert ? {
    id                        = aws_acm_certificate.cloudfront[0].id
    arn                       = aws_acm_certificate.cloudfront[0].arn
    domain_name               = aws_acm_certificate.cloudfront[0].domain_name
    status                    = aws_acm_certificate.cloudfront[0].status
    domain_validation_options = aws_acm_certificate.cloudfront[0].domain_validation_options
  } : null
}

output "cloudfront_certificate_arn" {
  description = "CloudFront certificate ARN (for quick reference)"
  value       = var.create_cloudfront_cert ? aws_acm_certificate.cloudfront[0].arn : null
}