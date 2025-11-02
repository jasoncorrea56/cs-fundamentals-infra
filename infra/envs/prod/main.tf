locals {
  app_ns = "default"
  app_sa = "csf-app" # ServiceAccount
}

module "ecr_csf" {
  source = "../../modules/ecr"
  name   = "cs-fundamentals"
}

module "vpc" {
  source       = "../../modules/vpc"
  name         = "csf"
  cidr_block   = "10.0.0.0/16"
  cluster_name = "csf-cluster"
  azs          = ["us-west-2a", "us-west-2b"]
}

module "eks" {
  source           = "../../modules/eks"
  cluster_name     = "csf-cluster"
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  cluster_role_arn = aws_iam_role.eks_cluster.arn
  node_role_arn    = aws_iam_role.eks_node.arn
}

module "irsa" {
  source       = "../../modules/irsa"
  cluster_name = module.eks.cluster_name
}

module "alb_irsa" {
  source            = "../../modules/alb_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  role_name         = "csf-alb-controller-role"
}

module "alb_controller_policy" {
  source      = "../../modules/alb_controller_policy"
  policy_name = "AWSLoadBalancerControllerIAMPolicy-Custom"
  role_name   = "csf-alb-controller-role"
}

module "alb_controller_chart" {
  source       = "../../modules/alb_controller_chart"
  cluster_name = module.eks.cluster_name
  region       = "us-west-2"
  vpc_id       = module.vpc.vpc_id
  role_arn     = module.alb_irsa.role_arn
}

module "externaldns_irsa" {
  source            = "../../modules/externaldns_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
}

module "externaldns_chart" {
  source       = "../../modules/externaldns_chart"
  cluster_name = module.eks.cluster_name
  role_arn     = module.externaldns_irsa.role_arn
  owner_id     = module.eks.cluster_name
  # Optional: Narrow scope
  # domain_filters = ["domain.com"]
  # zone_id_filters = ["Z123ABCDEF..."]
}

module "db_secret" {
  source = "../../modules/asm_secret"
  name   = "csf/db-url"
  db_url = var.db_url
}

module "irsa_db" {
  source            = "../../modules/irsa_secrets"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = local.app_ns
  service_account   = local.app_sa
  role_name         = "csf-app-secrets-role"
  secret_arn        = module.db_secret.arn
}

module "csi_driver" {
  source = "../../modules/csi_driver_chart"
}

module "csi_aws_provider" {
  source = "../../modules/csi_aws_provider_chart"
}

module "secret_sync" {
  source          = "../../modules/secret_sync"
  namespace       = local.app_ns
  app_sa          = local.app_sa
  role_arn        = module.irsa_db.role_arn
  spc_name        = "csf-db-spc"
  secret_name     = "csf/db-url"
  k8s_secret_name = "csf-db"
  region          = "us-west-2"

  depends_on = [
    module.csi_driver,
    module.csi_aws_provider
  ]
}
