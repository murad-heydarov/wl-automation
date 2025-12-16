# CloudFront + S3 Website Module

Simple module for creating CloudFront distribution with S3 origin for static websites.

## Features

- ✅ S3 bucket with website configuration
- ✅ CloudFront distribution with custom domain
- ✅ Origin Access Identity (OAI) for secure S3 access
- ✅ Custom error responses (SPA support)
- ✅ Compression enabled
- ✅ HTTPS redirect
- ✅ Configurable TTL

## Usage
```hcl
module "admin_cloudfront" {
  source = "../../modules/cloudfront-s3-website"

  domain_name     = "afftech.xyz"
  subdomain       = "admin"
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"

  tags = {
    Environment = "production"
    Project     = "WL-Automation"
  }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `domain_name` | string | - | Primary domain (e.g., 'afftech.xyz') |
| `subdomain` | string | - | Subdomain (e.g., 'admin') |
| `certificate_arn` | string | - | ACM certificate ARN (us-east-1) |
| `s3_index_document` | string | `"index.html"` | S3 index document |
| `s3_error_document` | string | `"index.html"` | S3 error document |
| `enable_versioning` | bool | `false` | Enable S3 versioning |
| `enable_compression` | bool | `true` | Enable CloudFront compression |
| `viewer_protocol_policy` | string | `"redirect-to-https"` | Viewer protocol policy |
| `price_class` | string | `"PriceClass_100"` | CloudFront price class |
| `min_ttl` | number | `0` | Minimum TTL |
| `default_ttl` | number | `3600` | Default TTL (1 hour) |
| `max_ttl` | number | `86400` | Maximum TTL (24 hours) |
| `tags` | map(string) | `{}` | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `fqdn` | Full domain name (e.g., admin.afftech.xyz) |
| `s3_bucket_name` | S3 bucket name |
| `s3_bucket_arn` | S3 bucket ARN |
| `cloudfront_distribution_id` | CloudFront distribution ID |
| `cloudfront_domain_name` | CloudFront domain (e.g., d123.cloudfront.net) |
| `cloudfront_hosted_zone_id` | CloudFront hosted zone ID |

## What gets created
```
admin.afftech.xyz
├── S3 Bucket: admin.afftech.xyz
│   ├── Website hosting enabled
│   ├── Public access blocked
│   └── Bucket policy (CloudFront OAI access)
│
└── CloudFront Distribution
    ├── Origin: S3 bucket via OAI
    ├── Alias: admin.afftech.xyz
    ├── Certificate: ACM (us-east-1)
    ├── Default behavior: redirect-to-https
    └── Custom error: 403 → 200 (SPA support)
```

## Notes

- S3 bucket name = FQDN (e.g., `admin.afftech.xyz`)
- CloudFront uses SNI (no dedicated IP)
- Compression enabled by default
- Custom error response for SPA apps (403 → index.html)