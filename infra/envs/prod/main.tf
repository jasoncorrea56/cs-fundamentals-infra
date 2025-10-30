module "ecr_csf" {
  source = "../../modules/ecr"
  name   = "cs-fundamentals"
}

output "ecr_repository_url" {
  value = module.ecr_csf.repository_url
}
