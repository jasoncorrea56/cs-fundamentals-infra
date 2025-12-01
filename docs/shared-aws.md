# Shared AWS Infrastructure (infra/envs/shared/aws)

Shared infrastructure includes:

- Root hosted zone (Route53)
- ACM wildcard certificate (`*.jasoncorrea.dev`)
- ECR repository
- GitHub OIDC + deployer role

Shared infra is applied in **two phases**.

---

## Phase 1 — Create hosted zone, GitHub OIDC, ECR, ACM (no validation)

### Disable ACM Validation

Set below in `infra/envs/shared/aws/terraform.tfvars`:

```hcl
enable_acm_validation = false
```

### Apply Infrastructure

```bash
export AWS_PROFILE=csf-terraform
cd infra/envs/shared/aws
terraform init -backend-config=backend.hcl -reconfigure
terraform apply -auto-approve

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
```

**Outputs:**

- `acm_csf_arn`
- `csf_ecr_repository_arn`
- `csf_ecr_repository_url`
- `github_deployer_role_arn`
- `github_oidc_provider_arn`
- `shared_zone_id`
- `shared_zone_name`
- `shared_zone_name_servers`

### Critical Step — Update Registrar

Use the `shared_zone_name_servers` output to update your DNS registrar.
**Wait ~5 minutes before continuing.**

---

## Phase 2 — Validate ACM certificate

### Enable ACM Validation

Set below in `infra/envs/shared/aws/terraform.tfvars`:

```hcl
enable_acm_validation = true
```

### Apply Validation

```bash
terraform apply -auto-approve

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

A final Terraform Plan should return **no changes** afterwards.
