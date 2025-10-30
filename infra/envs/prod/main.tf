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

# ------------ Outputs ------------ #

output "ecr_repository_url" {
  value = module.ecr_csf.repository_url
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
