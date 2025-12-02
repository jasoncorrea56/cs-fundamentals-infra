output "irsa_oidc_provider_arn" {
  value = module.irsa.oidc_provider_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.terraform_remote_state.shared.outputs.shared_zone_id
}

output "route53_name_servers" {
  description = "Name servers of the shared hosted zone"
  value       = data.terraform_remote_state.shared.outputs.shared_zone_name_servers
}

output "app_domain" {
  description = "Public app domain for this environment"
  value       = local.app_domain
}

output "github_actions_role_arn" {
  value       = data.aws_iam_role.gha_deployer.arn
  description = "IAM role ARN that GitHub Actions assumes (set as AWS_ROLE_TO_ASSUME)."
}

output "alb_sg_id" {
  description = "Security group used by the QA ALB"
  value       = module.alb_sg.security_group_id
}

output "cluster_name" {
  description = "EKS cluster name for this environment"
  value       = module.eks.cluster_name
}

output "eks_node_role_arn" {
  description = "IAM role used by EKS worker nodes"
  value       = aws_iam_role.eks_node.arn
}

output "vpc_cidr_block" {
  value = module.vpc.cidr_block
}

output "alb_controller_role_arn" {
  value = module.alb_irsa.role_arn
}

output "externaldns_role_arn" {
  value = module.externaldns_irsa.role_arn
}

output "cluster_autoscaler_role_arn" {
  value = module.cluster_autoscaler_irsa.role_arn
}

output "cloudwatch_agent_role_arn" {
  value = module.cloudwatch_irsa_agent.role_arn
}

output "fluent_bit_role_arn" {
  value = module.fluentbit_irsa.role_arn
}

output "app_secrets_role_arn" {
  value = module.irsa_db.role_arn
}

output "db_secret_arn" {
  value = module.db_secret.secret_arn
}

output "shared_zone_name" {
  value = data.terraform_remote_state.shared.outputs.shared_zone_name
}

output "shared_zone_id" {
  value = data.terraform_remote_state.shared.outputs.shared_zone_id
}
