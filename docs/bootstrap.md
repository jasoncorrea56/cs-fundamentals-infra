# Bootstrap (infra/bootstrap)

Bootstrap creates:

- Terraform backend (S3 + DynamoDB)
- Terraform operator IAM role
- Trust relationships allowing GitHub Actions + local Terraform to use the role

## 1. Configure AWS profile: `csf-bootstrap`

Manually create a CLI Admin User to bootstrap the account in the AWS Console.

Then, add the profile below to `~/.aws/config`.
Use the access & secret keys for the CLI Admin User obtained from the AWS Console.

```bash
[profile csf-bootstrap]
aws_access_key_id     = <CLI Admin User Access Key>
aws_secret_access_key = <CLI Admin User Access Secret>
region                = us-west-2
```

## 2. Set AWS profile

```bash
export AWS_PROFILE=csf-bootstrap
```

## 3. Apply bootstrap

```bash
cd infra/bootstrap
terraform plan
terraform apply

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.
```

**Outputs:**

- `terraform_role_arn`
- `tfstate_bucket`
- `tf_locks_table`

## 4. Configure AWS profile: `csf-terraform`

After the `infra/bootstrap/` apply succeeds, use the `terraform_role_arn` output to
specify the `csf-terraform` profile's `role_arn` (i.e. cs-fundamentals-terraform-operator).

Append the profile below to `~/.aws/config`:

```bash
...

[profile csf-terraform]
role_arn       = arn:aws:iam::<ACCOUNT>:role/cs-fundamentals-terraform-operator
source_profile = csf-bootstrap
region         = us-west-2
```
