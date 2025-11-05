variable "cluster_name" { type = string }
variable "region" { type = string }
variable "vpc_id" { type = string }
variable "role_arn" { type = string }
variable "namespace" {
  type    = string
  default = "kube-system"
}
variable "sa_name" {
  type    = string
  default = "aws-load-balancer-controller"
}
variable "chart_version" {
  type    = string
  default = "1.9.1"
}
