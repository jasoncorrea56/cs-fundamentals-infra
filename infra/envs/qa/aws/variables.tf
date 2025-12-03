variable "environment" {
  description = "Environment name (i.e., dev, prod, qa)"
  type        = string
  default     = "qa"
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

variable "service_account" {
  description = "Name of service account under which the app runs (i.e. csf-app)"
  type        = string
}

variable "db_url" {
  description = "Database connection URL"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "EKS cluster name override. If unset, defaults to <app_namespace>-<environment>-cluster for new envs."
  type        = string
  default     = null
}

variable "eks_cluster_role_name" {
  description = "IAM role name for the EKS control plane"
  type        = string
  default     = "csf-qa-eks-cluster-role"
}

variable "eks_node_role_name" {
  description = "IAM role name for the EKS node group"
  type        = string
  default     = "csf-qa-eks-node-role"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS minor version, i.e. 1.34"
  default     = "1.34"
}

variable "alb_name" {
  description = "Optional ALB name (i.e. k8s-...elb.amazonaws.com) used to gate runtime alerts lookup."
  type        = string
  default     = ""
}

variable "alb_dns_name" {
  description = "ALB DNS name (i.e. k8s-...elb.amazonaws.com). Required when enable_runtime_alerts=true."
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID (i.e. Zxxxxxxxx). Required when enable_runtime_alerts=true."
  type        = string
  default     = ""
}

variable "enable_runtime_alerts" {
  description = "Enable runtime CloudWatch alarms that depend on the ALB existing (5xx, latency, pod restarts)."
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
