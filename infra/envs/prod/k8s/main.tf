locals {
  environment     = var.environment
  app_name        = var.app_name
  app_namespace   = var.app_namespace
  service_account = var.service_account

  # Cluster name: "<namespace>-<env>-cluster"
  cluster_name = coalesce(var.cluster_name, "${var.app_namespace}-${var.environment}-cluster")
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = local.app_namespace
  }
}

module "alb_controller_chart" {
  source       = "../../../modules/alb_controller_chart"
  cluster_name = local.cluster_name
  region       = "us-west-2"
  vpc_id       = data.terraform_remote_state.prod_aws.outputs.vpc_id
  role_arn     = data.terraform_remote_state.prod_aws.outputs.alb_controller_role_arn

  depends_on = [
    data.terraform_remote_state.prod_aws,
  ]
}

module "externaldns_chart" {
  source       = "../../../modules/externaldns_chart"
  cluster_name = local.cluster_name
  namespace    = "kube-system"
  sa_name      = "external-dns"
  role_arn     = data.terraform_remote_state.prod_aws.outputs.externaldns_role_arn

  # Use the shared hosted zone (managed by envs/shared).
  owner_id        = local.cluster_name
  domain_filters  = [data.terraform_remote_state.shared.outputs.shared_zone_name]
  zone_id_filters = [data.terraform_remote_state.shared.outputs.shared_zone_id]

  depends_on = [
    data.terraform_remote_state.prod_aws,
    data.terraform_remote_state.shared,
  ]
}

module "csi_driver" {
  source = "../../../modules/csi_driver_chart"

  depends_on = [
    data.terraform_remote_state.prod_aws,
  ]
}

module "csi_aws_provider" {
  source = "../../../modules/csi_aws_provider_chart"

  depends_on = [
    module.csi_driver,
  ]
}

module "secret_sync" {
  source          = "../../../modules/secret_sync"
  namespace       = local.app_namespace
  app_sa          = local.service_account
  spc_name        = "${local.app_namespace}-db-spc"
  k8s_secret_name = "${local.app_namespace}-db"
  region          = "us-west-2"

  role_arn   = data.terraform_remote_state.prod_aws.outputs.app_secrets_role_arn
  secret_arn = data.terraform_remote_state.prod_aws.outputs.db_secret_arn

  enable = var.secret_sync_enable

  depends_on = [
    module.csi_aws_provider,
    module.csi_driver,
    module.security_policies,
    data.terraform_remote_state.prod_aws,
  ]
}

module "cluster_autoscaler" {
  source       = "../../../modules/cluster_autoscaler_chart"
  cluster_name = local.cluster_name
  region       = "us-west-2"
  role_arn     = data.terraform_remote_state.prod_aws.outputs.cluster_autoscaler_role_arn
  # chart_version   = "9.45.0" # Optional pin

  depends_on = [
    data.terraform_remote_state.prod_aws,
  ]
}

module "cloudwatch_agent_chart" {
  source       = "../../../modules/cloudwatch_agent_chart"
  cluster_name = local.cluster_name
  region       = "us-west-2"
  role_arn     = data.terraform_remote_state.prod_aws.outputs.cloudwatch_agent_role_arn

  depends_on = [
    data.terraform_remote_state.prod_aws,
  ]
}

module "aws_for_fluent_bit_chart" {
  source       = "../../../modules/aws_for_fluent_bit_chart"
  cluster_name = local.cluster_name
  region       = "us-west-2"
  role_arn     = data.terraform_remote_state.prod_aws.outputs.fluent_bit_role_arn

  depends_on = [
    data.terraform_remote_state.prod_aws,
  ]
}

module "security_policies" {
  source          = "../../../modules/security_policies"
  namespace       = local.app_namespace
  service_account = local.service_account
  app_port        = 8080
  ingress_cidrs   = [data.terraform_remote_state.prod_aws.outputs.vpc_cidr_block]

  # Prod: namespace is app/CI-managed
  manage_namespace = false

  app_selector = {
    key   = "app.kubernetes.io/name"
    value = local.app_name
  }

  allow_db_egress = {
    enabled = true
    cidrs   = [data.terraform_remote_state.prod_aws.outputs.vpc_cidr_block]
    ports   = [5432]
  }

  allow_https_egress = {
    enabled = true
  }

  depends_on = [
    kubernetes_namespace_v1.app,
    module.alb_controller_chart,
    module.externaldns_chart,
  ]
}

module "metrics_server_chart" {
  source = "../../../modules/metrics_server_chart"
}

module "app_chart" {
  source      = "../../../modules/app_chart"
  environment = local.environment

  # Allow env-specific bootstrapping control.
  enable     = var.app_chart_enable
  chart_path = abspath("${path.module}/../../../../../${local.app_name}/helm")

  # Prod uses the prod values file (public ingress/TLS)
  values_file = abspath("${path.module}/../../../../../${local.app_name}/helm/values-prod.yaml")

  acm_certificate_arn = data.terraform_remote_state.shared.outputs.acm_csf_arn
  namespace           = local.app_namespace
  release_name        = local.app_namespace

  ingress_hosts = [
    var.app_domain,
  ]

  image_overrides = [
    {
      name  = "image.tag"
      value = var.image_tag
    }
  ]

  depends_on = [
    module.metrics_server_chart,
    module.secret_sync,
    module.alb_controller_chart,
  ]
}
