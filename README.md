# cs-fundamentals-infra

![Terraform](https://img.shields.io/badge/Terraform-1.8+-5C4EE5?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EKS-orange?logo=amazonaws)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29+-326CE5?logo=kubernetes)
![CI](https://github.com/jasoncorrea56/cs-fundamentals-infra/actions/workflows/infra-validate.yml/badge.svg)
![Terraform Validate](https://img.shields.io/badge/validate-passing-brightgreen)
![tfsec](https://img.shields.io/badge/tfsec-active-blue?logo=tfsec)
![License: Apache-2.0 OR MIT](https://img.shields.io/badge/license-Apache--2.0%20OR%20MIT-green)

Infrastructure-as-code for the **cs-fundamentals** service.  
This repo provisions **multi-environment AWS infrastructure** (Dev, QA, Prod) including VPC, EKS, Route53, ACM, IAM/IRSA, ECR, and all cluster add-ons — fully automated and reproducible using Terraform.

Everything deploys with:

- No manual AWS console steps  
- Least privilege & IRSA everywhere  
- Deterministic, multi-phase K8s bring-up  
- Environment isolation with shared DNS  
- App deployments driven by CI/CD + Helm

---

## 🔧 Design Goals

- **Reproducible**: deterministic builds of AWS + K8s across all environments.  
- **Cost-first**: lean, minimal, pay-only-when-needed architecture.  
- **Secure**: no long-lived credentials, IRSA-bound service accounts, OIDC for CI/CD.  
- **Operational clarity**: observable, reversible changes; documented flows.  
- **No snowflakes**: all envs follow the same modules + patterns.  
- **12-Factor aligned**: clean separation of config, no baked secrets, immutable images.

---

## 📁 Repository Structure

```bash
infra/
├── bootstrap/         # Terraform operator role, S3 backend, DynamoDB lock table
├── envs/
│   ├── shared/        # Shared DNS, ACM, OIDC, ECR
│   ├── dev/           # Dev AWS + K8s
│   ├── qa/            # QA AWS + K8s
│   └── prod/          # Prod AWS + K8s
└── modules/           # Reusable module stack
docs/                  # Full documentation set
```

---

## 🚀 High-Level Workflow

1. **Bootstrap**  
   - Create Terraform operator role + backend  
   - Configure AWS profiles  

2. **Shared Infrastructure**  
   - Hosted zone, ACM, ECR, GitHub OIDC provider  

3. **Environment Bring-Up (Dev/QA/Prod)**  
   Each environment is deployed in two layers:  
   - `aws/` → VPC, EKS, IAM, DNS, secrets  
   - `k8s/` → Add-ons, IRSA bindings, secret sync, app Helm chart  

4. **Application Deployments**  
   - CI/CD builds/pushes versioned images to ECR  
   - Terraform-controlled Helm deployment installs the app per environment  
   - Each environment uses its own `values-<env>.yaml`

5. **Teardown (Reverse Order)**  
   - K8s → AWS → Shared → Bootstrap  

---

## 🔐 Security Model

- **Terraform operator role** assumed via AWS profile (`csf-terraform`)
- **GitHub Actions** authenticates via AWS OIDC (no long-lived secrets)
- **Kubernetes** uses IRSA service accounts for ALB Controller, ExternalDNS, CSI, autoscaler, secrets sync, and the application
- **Secrets** stored only in AWS Secrets Manager and delivered via CSI - nothing enters Terraform state or container images
- **State** stored remotely in S3 with DynamoDB locking

---

## 📚 Full Documentation (in `/docs`)

| Topic | File |
|-------|------|
| End-to-end environment bring-up | [`docs/README.md`](docs/README.md) |
| Terraform bootstrap | [`docs/bootstrap.md`](docs/bootstrap.md) |
| Shared AWS infra | [`docs/shared-aws.md`](docs/shared-aws.md) |
| Per-environment AWS | [`docs/env-aws.md`](docs/env-aws.md) |
| Per-environment Kubernetes | [`docs/env-k8s.md`](docs/env-k8s.md) |
| Create a new environment (QA example) | [`docs/new-environment.md`](docs/new-environment.md) |
| Full teardown order | [`docs/teardown.md`](docs/teardown.md) |

---

## 🧪 Development Workflow (Quick)

```bash
export AWS_PROFILE=csf-terraform
cd infra/envs/dev/aws
terraform plan
terraform apply

cd ../k8s
terraform apply  # phases controlled via tfvars
```

App deployments are handled via the **cs-fundamentals** application repo CI/CD.

---

## 📜 License

This project is **dual-licensed** under:

- **Apache License 2.0**
- **MIT License**

You may choose **either** license when using this software.

See the [LICENSE](LICENSE) and [NOTICE](NOTICE) files for details.
