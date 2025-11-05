terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
  # Enable remote state
  backend "s3" {}
}

provider "aws" {
  region = "us-west-2"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.csf.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.csf.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.csf.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.csf.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.csf.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.csf.token
  }
}

data "aws_eks_cluster" "csf" { name = module.eks.cluster_name }
data "aws_eks_cluster_auth" "csf" { name = module.eks.cluster_name }
