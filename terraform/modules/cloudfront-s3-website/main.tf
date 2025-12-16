# terraform/modules/cloudfront-s3-website/main.tf

# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Support both subdomain and root domain
  # subdomain = "@" → root domain (e.g., "trackingslapkong.com")
  # subdomain = "admin" → subdomain (e.g., "admin.afftech.xyz")
  fqdn = var.subdomain == "@" ? var.domain_name : "${var.subdomain}.${var.domain_name}"
}

# ============================================================================
# S3 Bucket
# ============================================================================

resource "aws_s3_bucket" "website" {
  bucket = local.fqdn

  tags = merge(
    var.tags,
    {
      Name      = local.fqdn
      Subdomain = var.subdomain
      Domain    = var.domain_name
    }
  )
}

# ============================================================================
# S3 Bucket Website Configuration
# ============================================================================

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.s3_index_document
  }

  error_document {
    key = var.s3_error_document
  }
}

# ============================================================================
# S3 Bucket Versioning
# ============================================================================

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ============================================================================
# S3 Bucket Public Access Block
# ============================================================================

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================================
# CloudFront Origin Access Control (OAC)
# ============================================================================

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = var.oac_name != "" ? var.oac_name : "${local.fqdn}-oac"
  description                       = "OAC for ${local.fqdn} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ============================================================================
# CloudFront Distribution
# ============================================================================

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${local.fqdn}"
  default_root_object = "index.html"
  aliases             = [local.fqdn]
  price_class         = var.price_class

  # Origin (S3) – OAC
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-${local.fqdn}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  # Default cache behavior
  default_cache_behavior {
    target_origin_id       = "S3-${local.fqdn}"
    viewer_protocol_policy = var.viewer_protocol_policy
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = var.enable_compression

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl
  }

  # Custom error responses
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses

    content {
      error_code         = custom_error_response.value.error_code
      response_code      = custom_error_response.value.response_code
      response_page_path = custom_error_response.value.response_page_path
    }
  }

  # SSL certificate
  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Geo restrictions (none)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(
    var.tags,
    {
      Name      = local.fqdn
      Subdomain = var.subdomain
      Domain    = var.domain_name
    }
  )
}

# ============================================================================
# S3 Bucket Policy — CloudFront Service Principal + SourceArn
# ============================================================================

data "aws_iam_policy_document" "s3_cloudfront_access" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.website.arn}/*"
    ]

    # Yalnız bu CloudFront distribution istifadə edə bilsin
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_cloudfront_access.json

  depends_on = [
    aws_s3_bucket_public_access_block.website
  ]
}
