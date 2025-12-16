# terraform/environments/prod/outputs.tf

output "main_domain_summary" {
  description = "Main domain summary"
  value = length(module.main_domain) > 0 ? {
    domain                     = var.domain
    zone_id                    = module.main_domain[0].zone_id
    regional_certificate_arn   = module.main_domain[0].regional_certificate_arn
    cloudfront_certificate_arn = module.main_domain[0].cloudfront_certificate_arn
    admin                      = module.main_domain[0].admin
    agent                      = module.main_domain[0].agent
    cdn                        = module.main_domain[0].cdn
    reports                    = module.main_domain[0].reports
    api_dns                    = module.main_domain[0].api_dns_record
  } : null
}

output "click_domain_summary" {
  description = "Click domain summary"
  value = length(module.click_domain) > 0 ? {
    domain                     = var.click_domain
    zone_id                    = module.click_domain[0].zone_id
    regional_certificate_arn   = module.click_domain[0].regional_certificate_arn
    cloudfront_certificate_arn = module.click_domain[0].cloudfront_certificate_arn
    click                      = module.click_domain[0].click
    cdn                        = module.click_domain[0].cdn
    reports                    = module.click_domain[0].reports
    root_alb_dns               = module.click_domain[0].root_alb_dns_record
  } : null
}

output "deployment_summary" {
  description = "Complete deployment summary"
  value = {
    wl_type      = var.wl_type
    alb_dns_name = var.alb_dns_name
    main_domain  = length(module.main_domain) > 0 ? module.main_domain[0] : null
    click_domain = length(module.click_domain) > 0 ? module.click_domain[0] : null
  }
}