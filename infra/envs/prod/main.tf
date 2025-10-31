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
  source        = "../../modules/externaldns_chart"
  cluster_name  = module.eks.cluster_name
  role_arn      = module.externaldns_irsa.role_arn
  owner_id      = module.eks.cluster_name
  # Optional: Narrow scope
  # domain_filters = ["domain.com"]
  # zone_id_filters = ["Z123ABCDEF..."]
}
