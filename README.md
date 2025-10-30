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

## Prerequisites

- Terraform ≥ 1.6
- AWS CLI configured locally
- An S3 backend + DynamoDB lock table for remote state management

## Workflow

1. Update Terraform configuration
2. `terraform plan` to review changes
3. `terraform apply` to provision/update resources
4. Deploy application via Helm in the app repo CI/CD

## Security

- ECR access is scoped using IAM + OIDC
- No long-lived credentials required
- Kubernetes service accounts leverage IRSA for AWS access

## State Management

Store Terraform state remotely using S3 (for remote state) + DynamoDB (for locking) to prevent local drift and enable safe collaboration.

### Create IAM tf-bootstrap User

- Create an IAM User: `tf-bootstrap`
- Create an IAM Policy: `TfBootstrapS3Dynamo`
  - Grant S3 & DynamoDB access using the policy contained in `infra/bootstrap/tf-bootstrap-iam-policy.json`

### Configure AWS Credentials

Use accesskey and secretid from `tf-bootstrap`

```bash
aws configure
```

Verify UserID and ARN

```bash
aws sts get-caller-identity
```

### Launch Remote State Management Infra

```bash
cd infra/bootstrap
terraform init
terraform plan \
  -var org="jasoncorrea56" \
  -var project="csfundamentals" \
  -var env="prod" \
  -var region="us-west-2"

terraform apply -auto-approve \
  -var org="jasoncorrea56" \
  -var project="csfundamentals" \
  -var env="prod" \
  -var region="us-west-2"
```

### Configure Terraform backend for Remote State

Update `envs/prod/backend.hcl` with the S3 bucket and DynamoDB table from the output of apply.

Run the command below to configure Terraform's remote state location:

```bash
cd infra/envs/prod
terraform init -backend-config=backend.hcl -reconfigure
```

### Teardown TF Backend Infra

The remaining infra state will be stored remotely in S3 but the TF backend state was written locally.

When tearing down the environment, after `terraform destroy` for the EKS infra is complete, run the command below against the local statefile to teardown the TF backend (or delete the S3 and DynamoDB table manually if state is lost or correupted):

```bash
cd infra/bootstrap
terraform destroy -auto-approve  -var org="jasoncorrea56" -var project="csfundamentals" -var env="prod" -var region="us-west-2"
```

## Usage

```bash
terraform login
terraform init -upgrade
terraform plan
terraform apply
```
