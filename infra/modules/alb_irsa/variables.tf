variable "cluster_name" { type = string }
variable "oidc_provider_arn" { type = string }
variable "sa_namespace" {
  type    = string
  default = "kube-system"
}
variable "sa_name" {
  type    = string
  default = "aws-load-balancer-controller"
}
variable "role_name" {
  type    = string
  default = "csf-alb-controller-role"
}

variable "tags" {
  description = "Base tags to apply to resources in this module"
  type        = map(string)
  default     = {}
}
