# ACM Certificate Module

Automatic AWS ACM certificate creation with DNS validation via Cloudflare.

## Overview

This module creates SSL/TLS certificates in AWS Certificate Manager (ACM) with automatic DNS validation using Cloudflare. It supports both regional certificates (for ALB/ELB) and CloudFront certificates (required to be in us-east-1).

## Features

- ✅ **Regional Certificate**: Created in `eu-central-1` for ALB/ELB
- ✅ **CloudFront Certificate**: Created in `us-east-1` for CloudFront distributions
- ✅ **Automatic DNS Validation**: Creates CNAME records in Cloudflare automatically
- ✅ **Auto-Wait**: Waits until certificates are fully validated (status: ISSUED)
- ✅ **Subject Alternative Names**: Support for wildcard and multiple domains
- ✅ **Zero Downtime**: Uses `create_before_destroy` lifecycle
- ✅ **Certificate Transparency**: AWS default logging enabled (best practice)

## Usage
```hcl
module "acm" {
  source = "../../modules/acm"

  domain_name = "example.com"
  subject_alternative_names = [
    "*.example.com",
    "www.example.com"
  ]

  cloudflare_zone_id = "abc123def456..."

  tags = {
    Environment = "production"
    Project     = "wl-automation"
    WL_Name     = "example"
  }

  # Required: Pass providers from parent
  providers = {
    aws            = aws
    aws.east       = aws.east
    cloudflare     = cloudflare
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |
| cloudflare | ~> 4.0 |

## Providers

This module requires **three providers** to be passed from the parent configuration:

- `aws` - Default AWS provider (eu-central-1)
- `aws.east` - AWS provider alias for us-east-1 (CloudFront requirement)
- `cloudflare` - Cloudflare provider for DNS management

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain_name | Primary domain name | `string` | n/a | yes |
| subject_alternative_names | List of SANs | `list(string)` | `[]` | no |
| cloudflare_zone_id | Cloudflare Zone ID | `string` | n/a | yes |
| tags | Additional resource tags | `map(string)` | `{}` | no |
| validation_timeout | Max validation wait time | `string` | `"45m"` | no |
| create_regional_cert | Create regional cert | `bool` | `true` | no |
| create_cloudfront_cert | Create CloudFront cert | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| regional_certificate_arn | Regional certificate ARN (for ALB) |
| cloudfront_certificate_arn | CloudFront certificate ARN (for CloudFront) |
| regional_validation_records | DNS validation records (regional) |
| cloudfront_validation_records | DNS validation records (CloudFront) |
| summary | Complete summary of certificates |

## How It Works

1. **Certificate Creation**: Creates ACM certificates in both regions
2. **DNS Record Creation**: Automatically adds CNAME validation records to Cloudflare
3. **Validation Wait**: Terraform waits until AWS validates the certificates (max 45 minutes)
4. **Output ARNs**: Returns certificate ARNs ready to use with ALB/CloudFront

## Certificate Transparency Logging

This module uses AWS default behavior for Certificate Transparency logging, which is **ENABLED**. This is required for modern browsers (Chrome, Firefox, Safari) and is considered best practice for security.

> **Note**: AWS Provider 5.x automatically enables Certificate Transparency logging by default. No additional configuration is needed.

## Example Output
```hcl
summary = {
  domain_name                = "example.com"
  subject_alternative_names  = ["*.example.com"]
  regional_enabled           = true
  cloudfront_enabled         = true
  regional_certificate_arn   = "arn:aws:acm:eu-central-1:..."
  cloudfront_certificate_arn = "arn:aws:acm:us-east-1:..."
  validation_records_count   = 4
}
```

## Notes

- Certificate validation typically takes 5-30 minutes
- DNS records are automatically removed when destroying the module
- CloudFront **requires** certificates to be in us-east-1
- Both certificates use the same validation records (AWS deduplicates)
- Certificates are tagged with module metadata for tracking
- Certificate Transparency logging is enabled by AWS default (no action needed)

## Troubleshooting

**Validation timeout:**
```
Error: timeout while waiting for state to become 'ISSUED'
```
Solution: Check Cloudflare DNS records are properly created. Sometimes DNS propagation is slow.

**Zone ID not found:**
```
Error: Cloudflare Zone ID must be 32 hexadecimal characters
```
Solution: Get zone ID from Cloudflare dashboard or use `data "cloudflare_zone"` in parent.

## License

Internal use only - Gr8 Tech
