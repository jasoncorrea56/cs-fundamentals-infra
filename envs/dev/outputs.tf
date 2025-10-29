output "ecr_repo_url" {
    value = module.ecr.repo_url
}

output "github_role_arn" {
    value = module.github_oidc_ecr_push.role_arn
}
