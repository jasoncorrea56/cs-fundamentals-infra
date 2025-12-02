# Environment Kubernetes Stack (Dev / QA / Prod)

Kubernetes provisioning is always done in **three phases**:

**Process is identical for all environments.**

Example: Dev

---

## Phase 1 — Bootstrap K8s Addons (no secret sync, no app chart)

To disable secret sync + app chart, set below in `infra/envs/dev/k8s/terraform.tfvars`:

```hcl
secret_sync_enable = false
app_chart_enable   = false
```

Apply:

```bash
cd infra/envs/dev/k8s
export AWS_PROFILE=csf-terraform
terraform init -backend-config=backend.hcl -reconfigure
terraform apply -auto-approve

Apply complete! Resources: 24 added, 0 changed, 0 destroyed.
```

This installs:

- ALB Controller
- ExternalDNS
- Cluster Autoscaler
- Fluent Bit
- CloudWatch Agent
- Namespace scaffolding
- Service accounts + IRSA bindings

---

## Phase 2 — Enable secret sync

Update tfvars:

```hcl
secret_sync_enable = true
```

Apply:

```bash
terraform apply -auto-approve

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

---

## Phase 3 — Deploy App Helm Chart

Update tfvars:

```hcl
app_chart_enable = true
```

Apply:

```bash
terraform apply -auto-approve

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

A final Terraform Plan should return **no changes** afterwards.

---

## Post‑deployment validation

```bash
kubectl -n csf get deploy,ingress -o wide
```

Proactively flush local DNS cache:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Send curls to each environment or run Postman Test Runner for the cs-fundamentals collection:

```bash
curl --location 'https://csf-dev.jasoncorrea.dev:443/api/v1/version'

{"app":"CS Fundamentals API","image-tag":"0.7.6-a71e692","version":"0.7.6"}
```
