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
  }

  # Enable remote state
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

data "terraform_remote_state" "shared" {
  backend = "s3"

  # Config from infra/envs/shared/aws/backend.hcl
  config = {
    bucket       = "jasoncorrea56-cs-fundamentals-tfstate-prod-${var.region}"
    key          = "envs/shared/aws/terraform.tfstate"
    region       = "${var.region}"
    use_lockfile = true
    encrypt      = true
  }
}
