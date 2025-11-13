variable "app_domain" {
  description = "FQDN for the app (i.e. csf.example-domain.com)"
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
  description = "Hosted zone name (i.e. example-domain.com.)"
  type        = string
  default     = null
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
  default     = "csf-cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS minor version, i.e. 1.34"
  default     = "1.34"
}

# --- Principals to grant cluster-admin (system:masters) via aws-auth ---
variable "console_admin_role_arns" {
  description = "List of IAM role ARNs (e.g., SSO/assumed roles) to map into system:masters"
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

# Optional: original ALB name like "k8s-csf-csfcsfun-145ebc3211"
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
