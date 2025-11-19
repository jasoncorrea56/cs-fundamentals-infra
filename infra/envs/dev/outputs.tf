output "irsa_oidc_provider_arn" {
  value = module.irsa.oidc_provider_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID (shared, managed by prod)."
  value       = data.aws_route53_zone.shared_hosted_zone.zone_id
}

output "route53_name_servers" {
  description = "Name servers of the shared hosted zone (managed by prod)."
  value       = data.aws_route53_zone.shared_hosted_zone.name_servers
}

output "app_domain" {
  description = "Application FQDN"
  value       = var.app_domain
}

output "github_actions_role_arn" {
  value       = data.aws_iam_role.gha_deployer.arn
  description = "IAM role ARN that GitHub Actions assumes (set as AWS_ROLE_TO_ASSUME)."
}
