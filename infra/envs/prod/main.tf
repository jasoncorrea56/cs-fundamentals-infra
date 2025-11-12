locals {
  app_ns = "csf"
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
  source             = "../../modules/eks"
  cluster_name       = "csf-cluster"
  kubernetes_version = var.kubernetes_version
  public_subnets     = module.vpc.public_subnets
  private_subnets    = module.vpc.private_subnets
  cluster_role_arn   = aws_iam_role.eks_cluster.arn
  node_role_arn      = aws_iam_role.eks_node.arn
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
  namespace         = "kube-system"
  sa_name           = "external-dns"
  role_name         = "csf-externaldns-role"
}

module "externaldns_chart" {
  source          = "../../modules/externaldns_chart"
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  sa_name         = "external-dns"
  role_arn        = module.externaldns_irsa.role_arn
  owner_id        = module.eks.cluster_name
  domain_filters  = [module.route53_zone.zone_name]
  zone_id_filters = [module.route53_zone.zone_id]
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

module "cluster_autoscaler_irsa" {
  source            = "../../modules/cluster_autoscaler_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = "kube-system"
  service_account   = "cluster-autoscaler-aws-cluster-autoscaler"
  role_name         = "csf-cluster-autoscaler-role"
}

module "cluster_autoscaler" {
  source       = "../../modules/cluster_autoscaler_chart"
  cluster_name = module.eks.cluster_name
  region       = "us-west-2"
  role_arn     = module.cluster_autoscaler_irsa.role_arn
  # chart_version   = "9.45.0" # Optional pin
}

module "cloudwatch_irsa_agent" {
  source            = "../../modules/cloudwatch_irsa_agent"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = "amazon-cloudwatch"
  service_account   = "cloudwatch-agent"
  role_name         = "csf-cloudwatch-agent-role"
}

module "fluentbit_irsa" {
  source            = "../../modules/fluentbit_irsa"
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.irsa.oidc_provider_arn
  namespace         = "amazon-cloudwatch"
  service_account   = "aws-for-fluent-bit"
  role_name         = "csf-fluent-bit-role"
}

module "cloudwatch_agent_chart" {
  source       = "../../modules/cloudwatch_agent_chart"
  cluster_name = module.eks.cluster_name
  region       = "us-west-2"
  role_arn     = module.cloudwatch_irsa_agent.role_arn
  # chart_version = "x.y.z"
  depends_on = [module.irsa]
}

module "aws_for_fluent_bit_chart" {
  source       = "../../modules/aws_for_fluent_bit_chart"
  cluster_name = module.eks.cluster_name
  region       = "us-west-2"
  role_arn     = module.fluentbit_irsa.role_arn
  # chart_version = "x.y.z"
  depends_on = [module.irsa]
}

module "acm_csf" {
  source = "../../modules/acm_cert"

  # App subdomain (csf.example-domain.com)
  domain_name = var.app_domain

  # Root domain (example-domain.com)
  subject_alternative_names = [var.zone_name]

  enable_validation = true
  hosted_zone_id    = module.route53_zone.zone_id
  region            = "us-west-2"
}

module "route53_zone" {
  source    = "../../modules/route53_zone"
  zone_name = var.zone_name
}

module "security_policies" {
  source        = "../../modules/security_policies"
  namespace     = local.app_ns
  app_port      = 8080
  ingress_cidrs = [module.vpc.cidr_block]

  app_selector = {
    key   = "app.kubernetes.io/name"
    value = "cs-fundamentals"
  }

  allow_db_egress = {
    enabled = true
    cidrs   = [module.vpc.cidr_block]
    ports   = [5432]
  }

  allow_https_egress = {
    enabled = true
  }

  depends_on = [
    module.eks,
    module.alb_controller_chart,
    module.externaldns_chart
  ]
}

module "metrics_server_chart" {
  source = "../../modules/metrics_server_chart"
}

module "app_chart" {
  source = "../../modules/app_chart"

  chart_path  = abspath("${path.module}/../../../../cs-fundamentals/helm")
  values_file = abspath("${path.module}/../../../../cs-fundamentals/helm/values-prod.yaml")

  acm_certificate_arn = module.acm_csf.certificate_arn
  namespace           = "csf"
  release_name        = "csf"

  ingress_hosts = [
    var.app_domain, # csf.example-domain.com
  ]

  # Optional: override image tag/repo at apply-time without touching values files
  image_overrides = [
    # { name = "image.repository", value = "948319129176.dkr.ecr.us-west-2.amazonaws.com/cs-fundamentals" },
    # { name = "image.tag",        value = "v0.2.5" },
  ]

  depends_on = [
    module.irsa_db,
    module.secret_sync,
    module.metrics_server_chart
  ]
}
