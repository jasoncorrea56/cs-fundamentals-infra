# Environment AWS Stack (Dev / QA / Prod)

Each environment contains:

- VPC + subnets  
- EKS cluster + nodegroups  
- IRSA roles (ALB Controller, ExternalDNS, Autoscaler, CloudWatch, Secrets Sync, App secrets)  
- Per‑environment DB URL secret (ASM)  
- Delegated DNS records under shared zone  
- Output: `app_domain`, `cluster_name`, IRSA ARNs

Shared infra is applied in **three phases**.

**Process is identical for all environments.**

---

## Apply AWS Environment

Example: Dev

```bash
export AWS_PROFILE=csf-terraform
cd infra/envs/dev/aws
terraform init -backend-config=backend.hcl -reconfigure
terraform apply -auto-approve

Apply complete! Resources: 59 added, 0 changed, 0 destroyed.
```

**Outputs:**

- `alb_controller_role_arn`
- `alb_sg_id`
- `app_domain`
- `app_secrets_role_arn`
- `cloudwatch_agent_role_arn`
- `cluster_autoscaler_role_arn`
- `cluster_name`
- `db_secret_arn`
- `eks_node_role_arn`
- `externaldns_role_arn`
- `fluent_bit_role_arn`
- `github_actions_role_arn`
- `irsa_oidc_provider_arn`
- `route53_name_servers`
- `route53_zone_id`
- `shared_zone_id`
- `shared_zone_name`
- `vpc_cidr_block`
- `vpc_id`

A final Terraform Plan should return **no changes** afterwards.

## Update KubeConfig

After apply, update KubeConfig for the new cluster identified by the `cluster_name` output.

1. Update kubeconfig:

    ```bash
    aws eks update-kubeconfig --name csf-dev-cluster --region us-west-2 --profile csf-terraform
    ```

2. Validate the new environment:

    ```bash
    kubectl config current-context
    kubectl get nodes
    kubectl -n csf get ingress -o wide
    ```

## Populate ECR

Run CI by raising a version bump PR in the `cs-fundamentals` repo.

**IMPORTANT**
Update `image_tag` in `infra/envs/dev/k8s/terraform.tfvars` to the version pushed to ECR by CI:

```hcl
image_tag       = "0.7.6-a71e692"
```
