# Full Teardown Guide

This document describes the **explicit, ordered teardown process** for the entire `cs-fundamentals-infra` project.  
Following this order guarantees clean destruction without dependency failures.

---

## ⚠️ Important Notes

- Teardowns must always go **K8s → AWS → Shared**.
- Never destroy shared infrastructure while any environment still exists.
- Always export the `csf-terraform` profile unless noted.
- All commands assume you are in the repo root.

---

## 1. Destroy Prod

### Step 1: Prod K8s

```bash
export AWS_PROFILE=csf-terraform
cd infra/envs/prod/k8s
terraform destroy -auto-approve
```

### Step 2: Prod AWS

```bash
cd ../aws
terraform destroy -auto-approve
```

---

## 2. Destroy QA

### Step 1: QA K8s

```bash
cd ../../../qa/k8s
terraform destroy -auto-approve
```

### Step 2: QA AWS

```bash
cd ../aws
terraform destroy -auto-approve
```

---

## 3. Destroy Dev

### Step 1: Dev K8s

```bash
cd ../../../dev/k8s
terraform destroy -auto-approve
```

### Step 2: Dev AWS

```bash
cd ../aws
terraform destroy -auto-approve
```

---

## 4. Destroy Shared (AWS Only)

```bash
cd ../../../shared/aws
terraform destroy -auto-approve
```

---

## 5. Destroy Bootstrap

```bash
cd ../../../bootstrap
export AWS_PROFILE=csf-bootstrap
terraform destroy -auto-approve
```

---

## 6. Cleanup (Local)

Optionally remove kube contexts:

```bash
kubectl config delete-context csf-dev-cluster
kubectl config delete-context csf-qa-cluster
kubectl config delete-context csf-prod-cluster
```

Flush DNS:

```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

---

## Teardown Complete 🎉

Your account is now fully reset and ready for a clean rebuild.
