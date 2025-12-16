# terraform/modules/gitlab-ci-variables/main.tf

# ============================================================================
# GitLab CI/CD Variables
# ============================================================================

locals {
  platform_code = upper(var.platform_code)
}

resource "gitlab_project_variable" "admin_bucket" {
  project           = var.gitlab_project_id
  key               = "${local.platform_code}_PROD_BUCKET_NAME"
  value             = "${var.admin_subdomain}.${var.domain}"
  protected         = var.protected
  masked            = var.masked
  environment_scope = var.environment_scope
  description       = "Admin bucket for ${var.domain} (${var.wl_type} WL)"
}

resource "gitlab_project_variable" "agent_bucket" {
    count = contains(["agent", "mixed"], var.wl_type) ? 1 : 0

  project           = var.gitlab_project_id
  key               = "${local.platform_code}_AGENT_PROD_BUCKET_NAME"
  value             = "${var.agent_subdomain}.${var.domain}"
  protected         = var.protected
  masked            = var.masked
  environment_scope = var.environment_scope
  description       = "Agent bucket for ${var.domain} (${var.wl_type} WL)"
}