
output "ecr_repository_url" {
  value = module.ecr_csf.repository_url
}

output "irsa_oidc_provider_arn" {
  value = module.irsa.oidc_provider_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
