# terraform/modules/gitlab-ci-variables/variables.tf

variable "gitlab_project_id" {
  description = "GitLab project ID (e.g., 'marketingtech/pmaffiliate/pmaffiliate-react-front')"
  type        = string
}

variable "domain" {
  description = "Domain name (e.g., 'liravegas.com')"
  type        = string
}

variable "wl_type" {
  description = "WL type: agent, click, or mixed"
  type        = string
  default     = "agent"

  validation {
    condition     = contains(["agent", "click", "mixed"], var.wl_type)
    error_message = "Must be 'agent', 'click', or 'mixed'."
  }
}

variable "platform_code" {
  description = "Platform code (e.g., 'LIRV') - REQUIRED"
  type        = string

  validation {
    condition     = length(var.platform_code) > 0
    error_message = "platform_code cannot be empty."
  }
}

variable "admin_subdomain" {
  description = "Admin subdomain (e.g., 'admin', 'adminagent')"
  type        = string
}

variable "agent_subdomain" {
  description = "Agent subdomain (e.g., 'agent')"
  type        = string
  default     = "agent"
}

variable "protected" {
  description = "Whether the variable is protected"
  type        = bool
  default     = false
}

variable "masked" {
  description = "Whether the variable is masked"
  type        = bool
  default     = false
}

variable "environment_scope" {
  description = "Environment scope (* for all environments)"
  type        = string
  default     = "*"
}