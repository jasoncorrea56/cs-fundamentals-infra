# ------------------------------------------------------------
# Route53 Outputs
# ------------------------------------------------------------

output "shared_zone_id" {
  description = "Hosted zone ID for jasoncorrea.dev"
  value       = aws_route53_zone.jasoncorrea.zone_id
}

output "shared_zone_name" {
  description = "Hosted zone name for jasoncorrea.dev"
  value       = aws_route53_zone.jasoncorrea.name
}

output "shared_zone_name_servers" {
  description = "Name servers for the shared hosted zone"
  value       = aws_route53_zone.jasoncorrea.name_servers
}

# ------------------------------------------------------------
# GitHub Identity Outputs
# ------------------------------------------------------------

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "github_deployer_role_arn" {
  value = aws_iam_role.gha_deployer.arn
}

# ------------------------------------------------------------
# Shared ECR Outputs
# ------------------------------------------------------------

output "csf_ecr_repository_url" {
  description = "ECR repository URL for cs-fundamentals"
  value       = module.ecr_csf.repository_url
}

output "csf_ecr_repository_arn" {
  description = "ECR repository ARN for cs-fundamentals"
  value       = module.ecr_csf.repository_arn
}

# ------------------------------------------------------------
# Shared ACM Outputs
# ------------------------------------------------------------

output "acm_csf_arn" {
  description = "Wildcard ACM cert ARN for *.jasoncorrea.dev"
  value       = module.acm_csf.certificate_arn
}
