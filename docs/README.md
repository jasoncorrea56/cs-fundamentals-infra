# cs-fundamentals-infra

This documentation describes the **end-to-end, ground‑up process** used to bootstrap, deploy, validate, and tear down the complete `cs-fundamentals` multi‑environment infrastructure on AWS using Terraform and EKS.  

It also includes a complete walkthrough for creating a **new environment** (i.e. QA) following the project’s multi‑environment Terraform pattern.

This repository follows strict standards:

- Deterministic infra and K8s provisioning  
- Strong separation between shared and per‑environment concerns  
- Least‑privilege and IRSA for all AWS→K8s access  
- Repeatable multi‑phase K8s deployment (bootstrap → converge → app chart)  
- No snowflakes — every environment is born the same way

Documentation is split into these sections:

- [`bootstrap.md`](bootstrap.md) — Provision the Terraform operator role + remote state backend  
- [`shared-aws.md`](shared-aws.md) — Shared DNS, ACM, GitHub OIDC, ECR  
- [`env-aws.md`](env-aws.md) — Environment AWS stack (Dev / QA / Prod)  
- [`env-k8s.md`](env-k8s.md) — 3‑phase Kubernetes provisioning  
- [`new-environment.md`](new-environment.md) — How to create a brand‑new environment
- [`teardown.md`](teardown.md) - How to teardown the full stack of environments and supporting infra

---

## Using terraform.tfvars.example for Local Setup

To make this repository easier to clone and experiment with, each environment now includes example variable files that show the required structure without exposing any secrets:

`infra/envs/<env>/aws/terraform.tfvars.example`
`infra/envs/<env>/k8s/terraform.tfvars.example`

These files contain safe placeholder values only (no credentials, no private data). They serve as a template for anyone configuring the project for the first time.

Terraform automatically loads `*.tfvars` but it does **not** automatically load files ending in `.example`.

### How to set up your local tfvars

For each environment (dev, qa, prod):

#### 1. Copy the example file

```bash
cd infra/envs/dev/aws
cp terraform.tfvars.example terraform.tfvars
```

Repeat for both **aws** and **k8s** layers. Terraform will then load the real variables automatically.

#### 2. Edit terraform.tfvars with real values

Update fields such as:

- app_domain  
- image_tag  
- secret_sync_enable  
- app_chart_enable  
- service_account  
- admin IAM ARNs  

Secrets remain safely stored in ASM.

#### 3. Initialize and plan

```bash
terraform init -backend-config=backend.hcl
terraform plan
```

### Never commit real tfvars

`.gitignore` already excludes:

- *.tfvars
- *.tfvars.json

Only commit the `.example` files. Real values should stay on your machine or in your automation environment.
