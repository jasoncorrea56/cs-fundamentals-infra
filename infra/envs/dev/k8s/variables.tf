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
  description = "FQDN for the app (i.e. csf-dev.jasoncorrea.dev)"
  type        = string
}

variable "service_account" {
  description = "Name of service account under which the app runs (i.e. csf-app)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name override. If unset, defaults to <app_namespace>-<environment>-cluster."
  type        = string
  default     = null
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
  description = "Container image tag to deploy in Dev (i.e. 0.7.7-<sha7>)."
  type        = string
  default     = "0.7.6-a71e692"
}
