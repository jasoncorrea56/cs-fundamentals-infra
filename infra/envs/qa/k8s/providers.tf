terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

  backend "s3" {}
}

provider "aws" {
  region = var.region
}

# Read cluster info from the qa/aws stack
data "terraform_remote_state" "qa_aws" {
  backend = "s3"
  config = {
    bucket       = "jasoncorrea56-cs-fundamentals-tfstate-bootstrap-${var.region}"
    key          = "envs/qa/aws/terraform.tfstate"
    region       = "${var.region}"
    use_lockfile = true
  }
}

data "terraform_remote_state" "shared" {
  backend = "s3"

  # Config from infra/envs/shared/aws/backend.hcl
  config = {
    bucket       = "jasoncorrea56-cs-fundamentals-tfstate-bootstrap-${var.region}"
    key          = "envs/shared/aws/terraform.tfstate"
    region       = "${var.region}"
    use_lockfile = true
    encrypt      = true
  }
}

# Derive EKS endpoint + CA from AWS directly, using the cluster_name from qa/aws outputs
data "aws_eks_cluster" "app" {
  name = data.terraform_remote_state.qa_aws.outputs.cluster_name
}

data "aws_eks_cluster_auth" "app" {
  name = data.terraform_remote_state.qa_aws.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.app.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.app.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.app.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.app.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.app.token
  }
}
