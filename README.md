# cs-fundamentals-infra

Terraform configuration for the cs-fundamentals service. Provisions and manages AWS resources including VPC, EKS cluster, node groups, IAM roles, and supporting controllers using Terraform. Enables reproducible, secure, cost-aware deployment of the application.

## Overview

This infrastructure includes:

- **VPC** with public/private subnets
- **EKS** cluster and managed node groups
- **IAM** roles and OIDC integration for GitHub Actions
- **ECR** repository for application images
- **Ingress** via AWS Load Balancer Controller (ALB)
- **Core cluster add-ons** (autoscaling, logging, etc.)

All resources are defined using Terraform, with no manual console configuration required.

## Goals

- End-to-end reproducibility
- Minimal operational cost
- Secure workload isolation
- Zero manual drift (GitOps-friendly)
- Clear separation from application code

## Structure

- /modules        # Reusable Terraform modules (vpc, eks, iam, etc.)
- /environments   # Environment-specific configurations (dev, staging, prod)
- main.tf         # Root module composition
- providers.tf    # AWS provider + backend config
- variables.tf    # Input variables
- outputs.tf      # Exported values (ECR URL, cluster info, etc.)

## Prerequisites

- Terraform ≥ 1.6
- AWS CLI configured locally
- An S3 backend + DynamoDB lock table (recommended)

## Workflow

1. Update Terraform configuration
2. `terraform plan` to review changes
3. `terraform apply` to provision/update resources
4. Deploy application via Helm in the app repo CI/CD

## State Management

Store Terraform state remotely using Terraform Cloud (TFC) to prevent local drift and enable safe collaboration.

## Security

- ECR access is scoped using IAM + OIDC
- No long-lived credentials required
- Kubernetes service accounts leverage IRSA for AWS access

## Usage

```bash
terraform login
terraform init -upgrade
terraform plan
terraform apply
```
