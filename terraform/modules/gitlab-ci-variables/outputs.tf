# terraform/modules/gitlab-ci-variables/outputs.tf

output "admin_variable" {
  description = "Admin GitLab CI/CD variable details"
  value = {
    key   = gitlab_project_variable.admin_bucket.key
    value = gitlab_project_variable.admin_bucket.value
  }
  sensitive = true
}

output "agent_variable" {
  description = "Agent GitLab CI/CD variable details"
  value = contains(["agent", "mixed"], var.wl_type) ? {
    key   = gitlab_project_variable.agent_bucket[0].key
    value = gitlab_project_variable.agent_bucket[0].value
  } : null
  sensitive = true
}

output "platform_code" {
  description = "Platform code (uppercase)"
  value       = upper(var.platform_code)
}