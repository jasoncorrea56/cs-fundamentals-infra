variable "cluster_name" { type = string }
variable "region" { type = string }
variable "role_arn" { type = string }
variable "namespace" {
  type    = string
  default = "kube-system"
}
variable "sa_name" {
  type    = string
  default = "cluster-autoscaler"
}
variable "chart_version" {
  type    = string
  default = null
}
