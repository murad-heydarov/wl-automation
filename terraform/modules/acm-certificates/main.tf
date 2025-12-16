# terraform/modules/acm-certificates/main.tf

# ============================================================================
# Regional ACM Certificate (eu-central-1)
# For: ALB, ELB, API Gateway
# ============================================================================

resource "aws_acm_certificate" "regional" {
  count = var.create_regional_cert ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name             = "${var.domain_name}-regional"
      CertificateType  = "Regional"
      Region           = "eu-central-1"
      ValidationMethod = "DNS"
    }
  )
}

# ============================================================================
# CloudFront ACM Certificate (us-east-1)
# ============================================================================

resource "aws_acm_certificate" "cloudfront" {
  count    = var.create_cloudfront_cert ? 1 : 0
  provider = aws.east

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle { create_before_destroy = true }

  tags = merge(
    var.tags,
    {
      Name             = "${var.domain_name}-cloudfront"
      CertificateType  = "CloudFront"
      Region           = "us-east-1"
      ValidationMethod = "DNS"
    }
  )
}
