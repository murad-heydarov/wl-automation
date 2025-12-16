# terraform/modules/cloudfront-s3-website/outputs.tf

# ============================================================================
# General Outputs
# ============================================================================

output "fqdn" {
  description = "Full domain name (e.g., admin.afftech.xyz)"
  value       = local.fqdn
}

# ============================================================================
# S3 Outputs
# ============================================================================

output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.website.bucket
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "s3_bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

output "s3_website_endpoint" {
  description = "S3 website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

# ============================================================================
# CloudFront Outputs
# ============================================================================

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name (e.g., d111111abcdef8.cloudfront.net)"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID (for Route53/DNS)"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "cloudfront_status" {
  description = "CloudFront distribution status"
  value       = aws_cloudfront_distribution.website.status
}

# ============================================================================
# OAC Outputs
# ============================================================================

output "oac_id" {
  description = "Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.website.id
}

output "oac_name" {
  description = "Origin Access Control name"
  value       = aws_cloudfront_origin_access_control.website.name
}

output "oac_etag" {
  description = "Origin Access Control ETag"
  value       = aws_cloudfront_origin_access_control.website.etag
}
