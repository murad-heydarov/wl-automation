# terraform/modules/wl-domain/main.tf

# ============================================================================
# Cloudflare Zone Lookup
# ============================================================================
data "cloudflare_zone" "zone" {
  filter = {
    name = var.domain
  }
}

locals {
  zone_id = "84787ea66aa226406e7c736892c6d493" # afftech.xyz
  sans    = var.sans != null && length(var.sans) > 0 ? var.sans : ["*.${var.domain}"]
}

# ============================================================================
# ACM Certificates (eu-central-1 + us-east-1)
# ============================================================================
module "acm" {
  source = "../acm-certificates"

  domain_name               = var.domain
  subject_alternative_names = local.sans

  create_regional_cert   = var.create_regional_cert
  create_cloudfront_cert = var.create_cloudfront_cert

  tags = var.tags

  providers = {
    aws      = aws
    aws.east = aws.east
  }
}

# ============================================================================
# DNS Validation
# ============================================================================
module "validation" {
  source = "../acm-dns-validation"

  domain_name        = var.domain
  cloudflare_zone_id = local.zone_id

  regional_certificate   = module.acm.regional_certificate
  cloudfront_certificate = module.acm.cloudfront_certificate

  validation_timeout = var.validation_timeout

  providers = {
    aws        = aws
    aws.east   = aws.east
    cloudflare = cloudflare
  }

  depends_on = [module.acm]
}

# ============================================================================
# Admin CloudFront + S3
# ============================================================================
module "admin" {
  count  = var.create_admin ? 1 : 0
  source = "../cloudfront-s3-website"

  domain_name     = var.domain
  subdomain       = var.admin_subdomain
  certificate_arn = module.validation.cloudfront_certificate_arn

  s3_index_document      = var.s3_index_document
  s3_error_document      = var.s3_error_document
  enable_versioning      = var.enable_versioning
  enable_compression     = var.enable_compression
  viewer_protocol_policy = var.viewer_protocol_policy
  price_class            = var.price_class
  min_ttl                = var.min_ttl
  default_ttl            = var.default_ttl
  max_ttl                = var.max_ttl
  custom_error_responses = var.custom_error_responses

  tags = merge(var.tags, {
    Subdomain = var.admin_subdomain
    Purpose   = "Admin Panel"
  })

  depends_on = [module.validation]
}

# ============================================================================
# Agent CloudFront + S3
# ============================================================================
module "agent" {
  count  = var.create_agent ? 1 : 0
  source = "../cloudfront-s3-website"

  domain_name     = var.domain
  subdomain       = var.agent_subdomain
  certificate_arn = module.validation.cloudfront_certificate_arn

  s3_index_document      = var.s3_index_document
  s3_error_document      = var.s3_error_document
  enable_versioning      = var.enable_versioning
  enable_compression     = var.enable_compression
  viewer_protocol_policy = var.viewer_protocol_policy
  price_class            = var.price_class
  min_ttl                = var.min_ttl
  default_ttl            = var.default_ttl
  max_ttl                = var.max_ttl
  custom_error_responses = var.custom_error_responses

  tags = merge(var.tags, {
    Subdomain = var.agent_subdomain
    Purpose   = "Agent Panel"
  })

  depends_on = [module.validation]
}

# ============================================================================
# Click Root Domain CloudFront + S3
# Uses "@" to indicate root domain (no subdomain)
# ============================================================================
module "click" {
  count  = var.create_click ? 1 : 0
  source = "../cloudfront-s3-website"

  domain_name     = var.domain
  subdomain       = "@" # Root domain indicator
  certificate_arn = module.validation.cloudfront_certificate_arn

  s3_index_document      = var.s3_index_document
  s3_error_document      = var.s3_error_document
  enable_versioning      = var.enable_versioning
  enable_compression     = var.enable_compression
  viewer_protocol_policy = var.viewer_protocol_policy
  price_class            = var.price_class
  min_ttl                = var.min_ttl
  default_ttl            = var.default_ttl
  max_ttl                = var.max_ttl
  custom_error_responses = var.custom_error_responses

  tags = merge(var.tags, {
    Subdomain = "@"
    Purpose   = "Click Domain (Root)"
  })

  depends_on = [module.validation]
}

# ============================================================================
# CDN CloudFront + S3
# ============================================================================
module "cdn" {
  count  = var.create_cdn ? 1 : 0
  source = "../cloudfront-s3-website"

  domain_name     = var.domain
  subdomain       = var.cdn_subdomain
  certificate_arn = module.validation.cloudfront_certificate_arn

  # CDN-specific configuration
  s3_index_document      = "index.html"
  s3_error_document      = "404.html"
  enable_versioning      = false
  enable_compression     = true
  viewer_protocol_policy = "redirect-to-https"
  price_class            = var.price_class

  # CDN cache settings - Long TTL for static assets
  min_ttl     = 0
  default_ttl = var.cdn_default_ttl
  max_ttl     = var.cdn_max_ttl

  custom_error_responses = [
    {
      error_code         = 403
      response_code      = 404
      response_page_path = "/404.html"
    },
    {
      error_code         = 404
      response_code      = 404
      response_page_path = "/404.html"
    }
  ]

  tags = merge(var.tags, {
    Subdomain = var.cdn_subdomain
    Purpose   = "CDN Static Assets"
  })

  depends_on = [module.validation]
}

# ============================================================================
# Reports CloudFront + S3
# ============================================================================
module "reports" {
  count  = var.create_reports ? 1 : 0
  source = "../cloudfront-s3-website"

  domain_name     = var.domain
  subdomain       = var.reports_subdomain
  certificate_arn = module.validation.cloudfront_certificate_arn

  # Reports-specific configuration
  s3_index_document      = "index.html"
  s3_error_document      = "error.html"
  enable_versioning      = var.reports_enable_versioning
  enable_compression     = true
  viewer_protocol_policy = "redirect-to-https"
  price_class            = var.reports_price_class

  # Reports cache settings - Medium TTL
  min_ttl     = 0
  default_ttl = 3600  # 1 hour
  max_ttl     = 86400 # 24 hours

  custom_error_responses = [
    {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    },
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  ]

  tags = merge(var.tags, {
    Subdomain = var.reports_subdomain
    Purpose   = "Reports Portal"
  })

  depends_on = [module.validation]
}

# ============================================================================
# DNS Records
# ============================================================================

# Admin CNAME
resource "cloudflare_dns_record" "admin" {
  count   = var.create_admin ? 1 : 0
  zone_id = local.zone_id

  name    = module.admin[0].fqdn
  type    = "CNAME"
  content = module.admin[0].cloudfront_domain_name
  ttl     = 1
  proxied = false

  comment = "Admin → CloudFront"
}

# Agent CNAME
resource "cloudflare_dns_record" "agent" {
  count   = var.create_agent ? 1 : 0
  zone_id = local.zone_id

  name    = module.agent[0].fqdn
  type    = "CNAME"
  content = module.agent[0].cloudfront_domain_name
  ttl     = 1
  proxied = false

  comment = "Agent → CloudFront"
}

# Click CNAME (Root Domain)
resource "cloudflare_dns_record" "click" {
  count   = var.create_click ? 1 : 0
  zone_id = local.zone_id

  name    = module.click[0].fqdn
  type    = "CNAME"
  content = module.click[0].cloudfront_domain_name
  ttl     = 1
  proxied = false

  comment = "Click (Root) → CloudFront"
}

# CDN CNAME
resource "cloudflare_dns_record" "cdn" {
  count   = var.create_cdn ? 1 : 0
  zone_id = local.zone_id

  name    = module.cdn[0].fqdn
  type    = "CNAME"
  content = module.cdn[0].cloudfront_domain_name
  ttl     = 1
  proxied = false

  comment = "CDN → CloudFront"
}

# Reports CNAME
resource "cloudflare_dns_record" "reports" {
  count   = var.create_reports ? 1 : 0
  zone_id = local.zone_id

  name    = module.reports[0].fqdn
  type    = "CNAME"
  content = module.reports[0].cloudfront_domain_name
  ttl     = 1
  proxied = false

  comment = "Reports → CloudFront"
}

# ============================================================================
# DNS Records - ALB
# ============================================================================

# API CNAME Record (api.{domain} → ALB)
# Created for: Agent, Click, Mixed WL (main domain only)
resource "cloudflare_dns_record" "api" {
  count   = var.create_api_record ? 1 : 0
  zone_id = local.zone_id

  name    = "api.${var.domain}"
  type    = "CNAME"
  content = var.alb_dns_name
  ttl     = 1
  proxied = true

  comment = "API → ALB (${var.wl_type} WL)"
}

# Root Domain CNAME Record ({domain} → ALB)
# Created for: Click domain (separate tracking domain)
# Example: trackingslapkong.com → ALB
resource "cloudflare_dns_record" "root_alb" {
  count   = var.create_root_record ? 1 : 0
  zone_id = local.zone_id

  name    = var.domain
  type    = "CNAME"
  content = var.alb_dns_name
  ttl     = 1
  proxied = true

  comment = "Click Domain (Root) → ALB"
}

# ============================================================================
# GitLab CI/CD Variables (Optional)
# ============================================================================

module "gitlab_variables" {
  count  = var.gitlab_project_id != null ? 1 : 0
  source = "../gitlab-ci-variables"

  gitlab_project_id = var.gitlab_project_id
  domain            = var.domain
  wl_type           = var.wl_type
  platform_code     = var.platform_code
  admin_subdomain   = var.admin_subdomain
  agent_subdomain   = var.agent_subdomain

  protected         = var.gitlab_variables_protected
  masked            = var.gitlab_variables_masked
  environment_scope = var.gitlab_environment_scope

  depends_on = [
    module.admin,
    module.agent
  ]
}

# ============================================================================
# Mailgun Integration (Optional)
# ============================================================================

module "mailgun" {
  count  = var.mail_domain != null ? 1 : 0
  source = "../mailgun"

  domain             = var.domain
  mail_domain        = var.mail_domain
  mailgun_region     = "eu" # Default to EU region
  cloudflare_zone_id = local.zone_id

  tags = merge(var.tags, {
    Purpose = "Email Support"
    WL_Type = var.wl_type
  })

  depends_on = [module.validation]
}