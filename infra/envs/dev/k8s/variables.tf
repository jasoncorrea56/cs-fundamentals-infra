variable "environment" {
  description = "Environment name (i.e., dev, prod, qa)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "app_name" {
  description = "Name of the app being hosted (i.e. cs-fundamentals)"
  type        = string
}

variable "app_namespace" {
  description = "Namespace for the app being hosted (i.e. csf)"
  type        = string
}

variable "app_domain" {
  description = "FQDN for the app (i.e. csf.jasoncorrea.dev)"
  type        = string
}

variable "github_repo" {
  description = "Github repo for the app (i.e. cs-fundamentals)"
  type        = string
}

variable "github_owner" {
  description = "Owner of the Github repo (i.e. jasoncorrea56)"
  type        = string
}

variable "service_account" {
  description = "Name of service account under which the app runs (i.e. csf-app)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID that owns app_domain"
  type        = string
  default     = ""
}

variable "db_url" {
  description = "Database connection URL"
  type        = string
  default     = ""
}

variable "zone_name" {
  description = "Hosted zone name (i.e. jasoncorrea.dev)"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "EKS cluster name override. If unset, defaults to <app_namespace>-<environment>-cluster for new envs."
  type        = string
  default     = null
}

variable "eks_cluster_role_name" {
  description = "IAM role name for the EKS control plane"
  type        = string
  default     = "csf-dev-eks-cluster-role"
}

variable "eks_node_role_name" {
  description = "IAM role name for the EKS node group"
  type        = string
  default     = "csf-dev-eks-node-role"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS minor version (i.e. 1.34)"
  default     = "1.34"
}

# --- Principals to grant cluster-admin (system:masters) via aws-auth ---
variable "console_admin_role_arns" {
  description = "List of IAM role ARNs (i.e., SSO/assumed roles) to map into system:masters"
  type        = list(string)
  default     = []
}

variable "console_admin_user_arns" {
  description = "List of IAM user ARNs to map into system:masters"
  type        = list(string)
  default     = []
}

# --- Apex ALIAS to ALB (optional) ---
variable "enable_apex_alias" {
  description = "Create Route53 apex A ALIAS to the ALB (requires ALB DNS + zone ID)."
  type        = bool
  default     = false
}

# Optional: ALB name like "k8s-csf-csfcsfun-123abc4321"
variable "alb_name" {
  type    = string
  default = ""
}

variable "alb_dns_name" {
  description = "ALB DNS name (i.e. k8s-...elb.amazonaws.com). Required when enable_apex_alias=true."
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID (i.e. Zxxxxxxxx). Required when enable_apex_alias=true."
  type        = string
  default     = ""
}

variable "enable_runtime_alerts" {
  description = "Enable runtime CloudWatch alarms that depend on the ALB existing (5xx, latency, etc)."
  type        = bool
  default     = false
}

variable "runtime_alert_email" {
  description = "Optional email address for receiving runtime alerts via SNS."
  type        = string
  default     = ""
}

variable "alb_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the public ALB for this env"
  type        = list(string)
}

variable "secret_sync_enable" {
  description = "Whether to create the SecretProviderClass + synced secret (see bootstrap notes)."
  type        = bool
  # IMPORTANT: from a totally clean cluster, this should start as false
  default = false
}

variable "app_chart_enable" {
  description = "Enable Helm-managed app deployment (disable for first bootstrap when secrets are not ready)."
  type        = bool
  default     = true
}

variable "image_tag" {
  type        = string
  description = "Container image tag to deploy in dev (i.e. 0.7.5-<sha7>)."
  default     = "0.7.5-2c5e092"
}
