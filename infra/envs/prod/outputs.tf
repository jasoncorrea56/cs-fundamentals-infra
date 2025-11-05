output "acm_certificate_arn" {
  description = "Validated ACM certificate ARN for ALB TLS"
  value       = module.acm_csf.certificate_arn
}

output "ecr_repository_url" {
  value = module.ecr_csf.repository_url
}

output "irsa_oidc_provider_arn" {
  value = module.irsa.oidc_provider_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.route53_zone.zone_id
}

output "route53_name_servers" {
  description = "Name servers to set at your domain registrar"
  value       = module.route53_zone.name_servers
}

output "app_domain" {
  description = "Application FQDN"
  value       = var.app_domain
}
