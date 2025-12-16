# terraform/environments/prod/main.tf

locals {
  common_tags = {
    Project     = "WL-Automation"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# Main Domain
# ============================================================================
module "main_domain" {
  count  = var.domain != null ? 1 : 0
  source = "../../modules/wl-domain"

  domain             = var.domain
  sans               = var.sans
  cloudflare_zone_id = var.cloudflare_zone_id
  wl_type            = var.wl_type
  platform_code      = var.platform_code

  # Subdomain configuration
  admin_subdomain = var.admin_subdomain
  agent_subdomain = var.agent_subdomain

  # Resource creation logic based on wl_type
  create_admin = true
  create_agent = contains(["agent", "mixed"], var.wl_type)
  create_click = var.wl_type == "mixed"

  # ALB DNS configuration
  alb_dns_name      = var.alb_dns_name
  create_api_record = true # Always create api.{domain} for main domain

  # GitLab CI/CD
  gitlab_project_id          = var.gitlab_project_id
  gitlab_variables_protected = false
  gitlab_variables_masked    = false
  gitlab_environment_scope   = "*"

  # Mailgun Configuration
  mail_domain = var.mail_domain

  tags = merge(
    local.common_tags,
    {
      WL_Name = split(".", var.domain)[0]
      Domain  = var.domain
      WL_Type = var.wl_type
    }
  )

  providers = {
    aws        = aws
    aws.east   = aws.east
    cloudflare = cloudflare
  }
}

# ============================================================================
# Separate Click Domain (for Click/Mixed WL types)
# ============================================================================
module "click_domain" {
  count  = var.click_domain != null ? 1 : 0
  source = "../../modules/wl-domain"

  domain             = var.click_domain
  cloudflare_zone_id = var.click_zone_id
  wl_type            = "click"
  platform_code      = var.platform_code

  create_admin = false
  create_agent = false
  create_click = true

  # ALB DNS configuration (click domain needs root record only)
  alb_dns_name       = var.alb_dns_name
  create_api_record  = false # No api.{click_domain}
  create_root_record = true  # Create {click_domain} → ALB

  # NO GitLab variables for separate click domain
  gitlab_project_id          = null
  gitlab_variables_protected = false
  gitlab_variables_masked    = false
  gitlab_environment_scope   = "*"

  tags = merge(
    local.common_tags,
    {
      WL_Name = split(".", var.click_domain)[0]
      Domain  = var.click_domain
      WL_Type = "click"
    }
  )

  providers = {
    aws        = aws
    aws.east   = aws.east
    cloudflare = cloudflare
  }
}