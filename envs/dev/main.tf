module "ecr" {
    source   = "../../modules/ecr"
    app_name = "cs-fundamentals"
}

module "github_oidc_ecr_push" {
    source      = "../../modules/github-oidc-ecr-push"
    github_org  = "jasoncorrea56"
    github_repo = "cs-fundamentals"
    # Optionally restrict to main: pass "refs/heads/main"
    github_ref  = "refs/heads/main"
    ecr_arn     = module.ecr.repo_arn
}
