variable "cluster_name" { type = string }
variable "owner_id" { type = string }
variable "role_arn" { type = string }
variable "namespace" {
  type    = string
  default = "kube-system"
}
variable "sa_name" {
  type    = string
  default = "external-dns"
}
variable "chart_version" {
  type    = string
  default = "8.7.1"
} # Bitnami chart
variable "domain_filters" {
  type    = list(string)
  default = []
}
variable "zone_id_filters" {
  type    = list(string)
  default = []
}
