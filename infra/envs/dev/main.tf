locals {
  # Logical environment name (dev, qa, prod, etc.)
  environment = var.environment

  # App and k8s config
  app_name = var.app_name
  app_ns   = var.app_namespace
  app_sa   = var.service_account

  # Cluster name: "<namespace>-<env>-cluster"
  cluster_name = coalesce(var.cluster_name, "${var.app_namespace}-${var.environment}-cluster")

  # DNS
  subdomain_prefix = "${local.app_ns}-${local.environment}"       # "csf-dev", "csf-qa", ...
  app_domain       = "${local.subdomain_prefix}.${var.zone_name}" # "csf-dev.jasoncorrea.dev"
}

# Dev uses the existing public hosted zone (created and managed by prod).
data "aws_route53_zone" "shared_hosted_zone" {
  name         = var.zone_name
  private_zone = false
}

module "vpc" {
  source       = "../../modules/vpc"
  name         = local.app_ns
  cidr_block   = "10.0.0.0/16"
  cluster_name = local.cluster_name
  azs          = ["us-west-2a", "us-west-2b"]
}

module "alb_sg" {
  source        = "../../modules/alb_sg"
  name_prefix   = "${local.app_ns}-${local.environment}-alb"
  vpc_id        = module.vpc.vpc_id
  allowed_cidrs = var.alb_allowed_cidrs
}

module "eks" {
  source             = "../../modules/eks"
  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version
  public_subnets     = module.vpc.public_subnets
  private_subnets    = module.vpc.private_subnets
  cluster_role_arn   = aws_iam_role.eks_cluster.arn
  node_role_arn      = aws_iam_role.eks_node.arn
}

module "irsa" {
  source       = "../../modules/irsa"
  cluster_name = module.eks.cluster_name

  depends_on = [module.eks]
}

module "alb_irsa" {
  source            = "../../modules/alb_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  role_name         = "${local.app_ns}-${local.environment}-alb-controller-role"

  depends_on = [module.eks]
}

module "alb_controller_policy" {
  source      = "../../modules/alb_controller_policy"
  policy_name = "AWSLoadBalancerControllerIAMPolicy-csf-${local.environment}"
  role_name   = "${local.app_ns}-${local.environment}-alb-controller-role"
}

module "alb_controller_chart" {
  source       = "../../modules/alb_controller_chart"
  cluster_name = module.eks.cluster_name
  region       = "us-west-2"
  vpc_id       = module.vpc.vpc_id
  role_arn     = module.alb_irsa.role_arn

  depends_on = [
    module.alb_irsa,
    module.vpc,
  ]
}

module "externaldns_irsa" {
  source            = "../../modules/externaldns_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = "kube-system"
  sa_name           = "external-dns"
  role_name         = "${local.app_ns}-${local.environment}-externaldns-role"

  depends_on = [module.eks]
}

module "externaldns_chart" {
  source       = "../../modules/externaldns_chart"
  cluster_name = module.eks.cluster_name
  namespace    = "kube-system"
  sa_name      = "external-dns"
  role_arn     = module.externaldns_irsa.role_arn

  # Use the existing hosted zone (managed by prod).
  owner_id        = module.eks.cluster_name
  domain_filters  = [data.aws_route53_zone.shared_hosted_zone.name]
  zone_id_filters = [data.aws_route53_zone.shared_hosted_zone.zone_id]
}

# TODO UNDO
data "aws_secretsmanager_secret" "db_url" {
  name = "${local.app_ns}/db-url"
}
# module "db_secret" {
#   source = "../../modules/asm_secret"
#   name   = "${local.app_ns}/db-url"
#   db_url = var.db_url
# }

module "irsa_db" {
  source            = "../../modules/irsa_secrets"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = local.app_ns
  service_account   = local.app_sa
  role_name         = "${local.app_ns}-${local.environment}-app-secrets-role"
  secret_arn        = data.aws_secretsmanager_secret.db_url.arn

  depends_on = [module.eks]
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
  spc_name        = "${local.app_ns}-db-spc"
  secret_arn      = data.aws_secretsmanager_secret.db_url.arn
  k8s_secret_name = "${local.app_ns}-db"
  region          = "us-west-2"

  depends_on = [
    module.csi_driver,
    module.csi_aws_provider
  ]
}

# module "cluster_autoscaler_irsa" {
#   source            = "../../modules/cluster_autoscaler_irsa"
#   cluster_name      = module.eks.cluster_name
#   oidc_provider_arn = module.irsa.oidc_provider_arn
#   namespace         = "kube-system"
#   service_account   = "cluster-autoscaler-aws-cluster-autoscaler"
#   role_name         = "${module.eks.cluster_name}-autoscaler-role"

#   depends_on = [module.eks]
# }

# module "cluster_autoscaler" {
#   source       = "../../modules/cluster_autoscaler_chart"
#   cluster_name = module.eks.cluster_name
#   region       = "us-west-2"
#   role_arn     = module.cluster_autoscaler_irsa.role_arn
#   # chart_version   = "9.45.0" # Optional pin
# }

# module "cloudwatch_irsa_agent" {
#   source            = "../../modules/cloudwatch_irsa_agent"
#   cluster_name      = module.eks.cluster_name
#   oidc_provider_arn = module.irsa.oidc_provider_arn
#   namespace         = "amazon-cloudwatch"
#   service_account   = "cloudwatch-agent"
#   role_name         = "${local.app_ns}-cloudwatch-agent-role"

#   depends_on = [module.eks]
# }

module "fluentbit_irsa" {
  source            = "../../modules/fluentbit_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = "amazon-cloudwatch"
  service_account   = "aws-for-fluent-bit"
  role_name         = "${local.app_ns}-${local.environment}-fluent-bit-role"

  depends_on = [module.eks]
}

# module "cloudwatch_agent_chart" {
#   source       = "../../modules/cloudwatch_agent_chart"
#   cluster_name = module.eks.cluster_name
#   region       = "us-west-2"
#   role_arn     = module.cloudwatch_irsa_agent.role_arn
#   # chart_version = "x.y.z"

#   depends_on = [module.irsa]
# }

# module "aws_for_fluent_bit_chart" {
#   source       = "../../modules/aws_for_fluent_bit_chart"
#   cluster_name = module.eks.cluster_name
#   region       = "us-west-2"
#   role_arn     = module.fluentbit_irsa.role_arn
#   # chart_version = "x.y.z"

#   depends_on = [module.irsa]
# }

# module "security_policies" {
#   source          = "../../modules/security_policies"
#   namespace       = local.app_ns
#   service_account = var.service_account
#   app_port        = 8080
#   ingress_cidrs   = [module.vpc.cidr_block]

#   app_selector = {
#     key   = "app.kubernetes.io/name"
#     value = local.app_name
#   }

#   allow_db_egress = {
#     enabled = true
#     cidrs   = [module.vpc.cidr_block]
#     ports   = [5432]
#   }

#   allow_https_egress = {
#     enabled = true
#   }

#   depends_on = [
#     module.eks,
#     module.alb_controller_chart,
#     module.externaldns_chart
#   ]
# }

module "metrics_server_chart" {
  source = "../../modules/metrics_server_chart"
}

# module "app_chart" {
#   source = "../../modules/app_chart"

#   chart_path  = abspath("${path.module}/../../../../${local.app_name}/helm")
#   # For dev, use the base values (no public ingress/TLS by default).
#   values_file = abspath("${path.module}/../../../../${local.app_name}/helm/values.yaml")

#   # Dev runs internal-only for now (no ACM / TLS).
#   acm_certificate_arn = ""

#   namespace    = local.app_ns
#   release_name = local.app_ns

#   # No public ingress hosts for dev yet.
#   ingress_hosts = []

#   # Optional: override image tag/repo at apply-time without touching values files
#   image_overrides = [
#     # { name = "image.repository", value = "948319129176.dkr.ecr.us-west-2.amazonaws.com/${local.app_name}" },
#     # { name = "image.tag",        value = "v0.2.5-dev" },
#   ]

#   depends_on = [
#     module.irsa_db,
#     module.secret_sync,
#     module.metrics_server_chart,
#   ]
# }
