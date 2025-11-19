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

### Create IAM `tf-bootstrap` User

- Create an IAM User: `tf-bootstrap`
- Create an IAM Policy: `TfBootstrapS3Dynamo`
  - Grant S3 & DynamoDB access using the policy contained in `infra/bootstrap/tf-bootstrap-iam-policy.json`

### GitHub Repository

Set Repository Variables:

- AWS_ROLE_TO_ASSUME=tf-bootstrap
- AWS_REGION=us-west-2
- EKS_CLUSTER_NAME = csf-cluster
- ECR_REGISTRY=<AWS_ACCOUNT>.dkr.ecr.us-west-2.amazonaws.com/cs-fundamentals
- APP_DOMAIN=csf.jasoncorrea.dev
- ACM_CERT_ARN=<ACM Certificate ARN returned from `terraform apply`>

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

Update `envs/prod/backend.hcl` with the S3 bucket and DynamoDB table from the output of apply above.

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

## Verify EKS Cluster

Run the CLI commands below to confirm the cluster and nodegroup are `ACTIVE`.

```bash
aws eks describe-cluster --name csf-cluster --region us-west-2 --query 'cluster.status'

aws eks describe-nodegroup --cluster-name csf-cluster --nodegroup-name csf-cluster-ng --region us-west-2 --query 'nodegroup.status'
```

## Terraform Linting

From the project root, format and validate all Terraform files.

```bash
terraform fmt -recursive
terraform validate
```

## Secrets

Secrets are retrieved from `infra/envs/prod/*.tfvars` at runtime. Although `cs-fundamentals` does not require secrets at this time, it has been wired up to support them for future use.

The only secret `db_url` is used for demo purposes. Specify in your local .tfvars prior to running `terraform apply -auto-approve`:

```bash
db_url = "postgresql://user_name:password@host_name:5432/dbname"
```

## Adding a New Environment (qa, staging, etc.)

This project is wired so that adding a new Kubernetes environment (i.e. `qa`) is mostly a matter of:

- Copying the existing `dev` Terraform env
- Adjusting a small set of variables
- Adding a matching Helm values file in the app repo

The pattern is the same for `qa`, `staging`, or any future envs.

---

### 1. DNS & Shared Hosted Zone (one-time per domain)

This repo assumes a shared public Route53 hosted zone for the apex domain
(i.e. `jasoncorrea.dev`) managed by Terraform in `infra/envs/shared`.

That env should already:

- Create `aws_route53_zone "jasoncorrea.dev"`
- Store the zone ID and name servers (see `infra/modules/route53_zone`)

If you ever introduce a new apex domain, add it here and point your domain
registrar to the Route53 name servers.

---

### 2. Copy the `dev` environment to create `qa`

From the `infra/envs` directory:

```bash
cd infra/envs
cp -r dev qa
```

You now have a new Terraform root at `infra/envs/qa` that mirrors `dev`.

In `infra/envs/qa/terraform.tfvars`, adjust the env-specific bits, for example:

```hcl
environment       = "qa"
app_name          = "cs-fundamentals"
app_namespace     = "csf"
service_account   = "csf-app"

# Shared apex domain managed by infra/envs/shared
zone_name         = "jasoncorrea.dev"

# CIDRs allowed to hit the QA ALB
# (i.e. VPN, office, or your own IP for now)
alb_allowed_cidrs = [
  "203.0.113.10/32", # replace with real CIDR(s)
]

# GitHub wiring (same as dev unless you change repos/owners)
github_owner      = "jasoncorrea56"
github_repo       = "cs-fundamentals"
```

> Note: `app_domain` is **not** set in `terraform.tfvars`.  
> The app FQDN is derived in `locals` as:
> `csf-<environment>.jasoncorrea.dev` (i.e. `csf-qa.jasoncorrea.dev`).

---

### 3. How Terraform derives names per environment

`infra/envs/<env>/main.tf` uses consistent naming for all envs:

- `cluster_name` > `"<namespace>-<env>-cluster"`  
  i.e. `csf-dev-cluster`, `csf-qa-cluster`
- `subdomain_prefix` > `"<namespace>-<env>"`  
  i.e. `csf-dev`, `csf-qa`
- `app_domain` > `"<subdomain_prefix>.<zone_name>"`  
  i.e. `csf-dev.jasoncorrea.dev`, `csf-qa.jasoncorrea.dev`

The `app_domain` is exported as an output, keeping all envs following the same pattern without hard-coding per-env FQDNs.

---

### 4. ALB security group per environment

Each env creates its own ALB security group via the `alb_sg` module:

- `name_prefix` > `csf-dev-alb`, `csf-qa-alb`, etc.
- `allowed_cidrs` is passed from `terraform.tfvars` per env.

This lets you lock down QA to VPN/office IPs while leaving prod open
(or protected via WAF) without changing module code.

---

### 5. ExternalDNS wiring per environment

All envs share the same apex zone (`jasoncorrea.dev`), but publish different
subdomains. `infra/envs/<env>/main.tf` wires up ExternalDNS.

ExternalDNS then manages records like:

- `csf-dev.jasoncorrea.dev` > Dev ALB
- `csf-qa.jasoncorrea.dev` > QA ALB
- `csf.jasoncorrea.dev` > Prod ALB

All contained within the same hosted zone.

---

### 6. Helm configuration in the app repo (per env)

In the **app repo**, environments are handled via separate values files:

- `helm/values.yaml` > Base - env-agnostic
- `helm/values-dev.yaml` > Dev-specific (host, tags, etc.)
- `helm/values-qa.yaml` > QA-specific
- `helm/values-prod.yaml` > Prod-specific

Example `helm/values-qa.yaml`:

```yaml
ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /api/v1/healthz
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/tags: "Environment=qa,Service=cs-fundamentals"
  hosts:
    - host: csf-qa.jasoncorrea.dev
      paths:
        - path: /
          pathType: Prefix
  tls:
    enabled: false  # enable + configure ACM later for HTTPS
```

Deploy QA with:

```bash
helm upgrade --install csf ./helm \
  --namespace csf \
  --create-namespace \
  -f helm/values.yaml \
  -f helm/values-qa.yaml
```

This pattern keeps the chart itself generic while env-specific knobs
live in small overlay files.

---

### 7. Bringing up a new environment end-to-end summary

To add `qa` (or any new env):

1. **DNS (one-time per domain)**
   - Ensure `infra/envs/shared` has created the public hosted zone
     for `jasoncorrea.dev` and that your registrar points to Route53.

2. **Terraform env**
   - `cp -r infra/envs/dev infra/envs/qa`
   - Update `terraform.tfvars`:
     - `environment = "qa"`
     - `zone_name = "jasoncorrea.dev"`
     - `alb_allowed_cidrs = [...]`
   - Run `terraform init -backend-config=backend.hcl`
   - Run `terraform plan` and `terraform apply`

3. **Helm env values**
   - Create `helm/values-qa.yaml` in the app repo based on `values-dev.yaml`
   - Set `ingress.hosts[0].host` to `csf-qa.jasoncorrea.dev`
   - Deploy with:

     ```bash
     helm upgrade --install csf ./helm \
       --namespace csf \
       --create-namespace \
       -f helm/values.yaml \
       -f helm/values-qa.yaml
     ```

Once these steps are done, QA should be reachable at `http(s)://csf-qa.jasoncorrea.dev`,
following the same patterns and guardrails as the existing `dev` environment.
