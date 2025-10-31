terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  # Enable remote state
  backend "s3" {}
}

provider "aws" {
  region = "us-west-2"
}
