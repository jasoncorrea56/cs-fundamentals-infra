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
