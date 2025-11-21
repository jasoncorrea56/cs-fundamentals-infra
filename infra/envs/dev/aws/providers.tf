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

data "terraform_remote_state" "shared" {
  backend = "s3"

  # Config from infra/envs/shared/backend.hcl
  config = {
    bucket       = "jasoncorrea56-csfundamentals-tfstate-prod-us-west-2"
    key          = "shared/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true
    encrypt      = true
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_data)
  token                  = data.aws_eks_cluster_auth.app.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_data)
    token                  = data.aws_eks_cluster_auth.app.token
  }
}

data "aws_eks_cluster" "app" { name = module.eks.cluster_name }
data "aws_eks_cluster_auth" "app" { name = module.eks.cluster_name }
