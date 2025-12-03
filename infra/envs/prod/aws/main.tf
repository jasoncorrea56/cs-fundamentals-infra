locals {
  # Logical environment name (dev, qa, prod, etc.)
  environment = var.environment
  region      = var.region

  # App and k8s config
  app_name = var.app_name
  app_ns   = var.app_namespace
  app_sa   = var.service_account

  # Cluster name: "<namespace>-<env>-cluster" unless overridden
  cluster_name = coalesce(var.cluster_name, "${var.app_namespace}-${var.environment}-cluster")

  # Optional DNS convenience (currently not wired into modules here,
  # but aligned with dev/aws for future use).
  subdomain_prefix = "${local.app_ns}-${local.environment}"
  app_domain       = "${local.subdomain_prefix}.${data.terraform_remote_state.shared.outputs.shared_zone_name}"

  # Base tags for all prod resources
  common_tags = {
    Application = local.app_name
    Environment = local.environment
    Namespace   = local.app_ns
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source       = "../../../modules/vpc"
  name         = local.app_ns
  cidr_block   = "10.0.0.0/16"
  cluster_name = local.cluster_name
  azs = [
    "${local.region}a",
    "${local.region}b"
  ]
  environment = local.environment

  tags = local.common_tags
}

module "alb_sg" {
  source        = "../../../modules/alb_sg"
  name_prefix   = "${local.app_ns}-${local.environment}-alb"
  vpc_id        = module.vpc.vpc_id
  allowed_cidrs = var.alb_allowed_cidrs

  tags = local.common_tags

  depends_on = [module.vpc]
}

module "eks" {
  source             = "../../../modules/eks"
  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version
  public_subnets     = module.vpc.public_subnets
  private_subnets    = module.vpc.private_subnets
  cluster_role_arn   = aws_iam_role.eks_cluster.arn
  node_role_arn      = aws_iam_role.eks_node.arn

  tags = local.common_tags

  depends_on = [
    module.vpc,
    aws_cloudwatch_log_group.eks_cluster,
  ]
}

module "irsa" {
  source       = "../../../modules/irsa"
  cluster_name = module.eks.cluster_name

  depends_on = [module.eks]
}

module "alb_irsa" {
  source            = "../../../modules/alb_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  role_name         = "${local.app_ns}-${local.environment}-alb-controller-role"

  tags = local.common_tags

  depends_on = [
    module.eks,
    module.irsa,
  ]
}

module "alb_controller_policy" {
  source      = "../../../modules/alb_controller_policy"
  policy_name = "AWSLoadBalancerControllerIAMPolicy-csf-${local.environment}"
  role_name   = "${local.app_ns}-${local.environment}-alb-controller-role"

  tags = local.common_tags

  depends_on = [module.alb_irsa]
}

module "externaldns_irsa" {
  source            = "../../../modules/externaldns_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = "kube-system"
  sa_name           = "external-dns"
  role_name         = "${local.app_ns}-${local.environment}-externaldns-role"

  tags = local.common_tags

  depends_on = [
    module.eks,
    module.irsa,
  ]
}

module "db_secret" {
  source = "../../../modules/asm_secret"

  # Per-env secret name (i.e. csf/prod/db-url)
  name   = "${local.app_ns}/${local.environment}/db-url"
  db_url = var.db_url

  tags = local.common_tags
}

module "irsa_db" {
  source            = "../../../modules/irsa_secrets"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = local.app_ns
  service_account   = local.app_sa
  role_name         = "${local.app_ns}-${local.environment}-app-secrets-role"
  secret_arn        = module.db_secret.secret_arn

  tags = local.common_tags

  depends_on = [
    module.db_secret,
    module.eks,
    module.irsa,
  ]
}

module "cluster_autoscaler_irsa" {
  source            = "../../../modules/cluster_autoscaler_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = "kube-system"
  service_account   = "cluster-autoscaler-aws-cluster-autoscaler"
  role_name         = "${module.eks.cluster_name}-autoscaler-role"

  tags = local.common_tags

  depends_on = [
    module.eks,
    module.irsa,
  ]
}

module "cloudwatch_irsa_agent" {
  source            = "../../../modules/cloudwatch_irsa_agent"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = "amazon-cloudwatch"
  service_account   = "cloudwatch-agent"
  role_name         = "${local.app_ns}-${local.environment}-cloudwatch-agent-role"

  tags = local.common_tags

  depends_on = [
    module.eks,
    module.irsa,
  ]
}

module "fluentbit_irsa" {
  source            = "../../../modules/fluentbit_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = "amazon-cloudwatch"
  service_account   = "aws-for-fluent-bit"
  role_name         = "${local.app_ns}-${local.environment}-fluent-bit-role"

  tags = local.common_tags

  depends_on = [
    module.eks,
    module.irsa,
  ]
}
