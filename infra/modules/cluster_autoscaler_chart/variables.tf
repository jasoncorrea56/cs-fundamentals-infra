variable "cluster_name" {
  description = "EKS cluster name for this environment"
  type        = string
}

variable "region" {
  description = "AWS region where the cluster runs"
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN used for IRSA (annotated on the ServiceAccount)"
  type        = string
}

variable "chart_version" {
  description = "Helm chart version for cluster-autoscaler"
  type        = string
  default     = "9.52.1"
}
