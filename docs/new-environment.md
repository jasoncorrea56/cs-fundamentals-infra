# Creating a New Environment (Example: QA)

This is the repeatable process for adding any new environment  
(i.e. `qa`, `staging`, `perf`, etc.)

Every environment has two folders:

```bash
infra/envs/<env>/aws
infra/envs/<env>/k8s
```

You can copy Dev as a template.

---

## 1. Copy Dev to QA

From repo root:

```bash
cp -R infra/envs/dev infra/envs/qa
```

Update the components below by searching in `infra/envs/qa` for `dev` and replacing with `qa`:

- Folder names inside tfvars
- Cluster name (`csf-qa-cluster`)
- Environment name variables
- All IAM role names to use `qa-` prefix
- DB secret paths (`csf/qa/db-url`)

---

## 2. Apply QA AWS

```bash
cd infra/envs/qa/aws
export AWS_PROFILE=csf-terraform
terraform init -backend-config=backend.hcl -reconfigure
terraform plan
terraform apply -auto-approve

Apply complete! Resources: 59 added, 0 changed, 0 destroyed.
```

Update kubeconfig:

```bash
aws eks update-kubeconfig --name csf-qa-cluster --region us-west-2 --profile csf-terraform
```

---

## 3. Create QA Helm Chart

Create a Helm chart for the new QA environment in the `cs-fundamentals` repo.

Use the Dev Helm chart as a template for QA.

```bash
cp helm/values-dev.yaml helm/values-qa.yaml
```

Search for `dev` and replace with `qa`.

---

## 4. Apply QA K8s (3 phases)

### Phase 1 — Bootstrap K8s Addons (no secret sync, no app chart)

Disable secret sync + app chart - set below in `infra/envs/qa/k8s/terraform.tfvars`:

```hcl
secret_sync_enable = false
app_chart_enable   = false
```

Apply:

```bash
cd infra/envs/qa/k8s
export AWS_PROFILE=csf-terraform
terraform init -backend-config=backend.hcl -reconfigure
terraform apply -auto-approve

Apply complete! Resources: 24 added, 0 changed, 0 destroyed.
```

### Phase 2 — Enable Secret Sync

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

### Phase 3 — Deploy App Helm Chart

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

## 5. Validate Env

```bash
kubectl config current-context
kubectl get nodes
kubectl -n csf get ingress -o wide
```

Proactively flush local DNS cache:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

Send curls to the new environment:

```bash
curl --location 'https://csf-qa.jasoncorrea.dev:443/api/v1/version'

{"app":"CS Fundamentals API","image-tag":"0.7.6-a71e692","version":"0.7.6"}
```

New environments should now be fully online and identical to Dev/Prod.
