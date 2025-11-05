variable "chart_version" {
  type    = string
  default = null
}
variable "cluster_name" { type = string }
variable "namespace" {
  type    = string
  default = "amazon-cloudwatch"
}
variable "region" { type = string }
variable "role_arn" { type = string }
