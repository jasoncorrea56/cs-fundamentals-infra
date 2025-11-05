variable "cluster_name" { type = string }
variable "oidc_provider_arn" { type = string }
variable "namespace" {
  type    = string
  default = "kube-system"
}
variable "sa_name" {
  type    = string
  default = "external-dns"
}
variable "role_name" {
  type    = string
  default = "csf-externaldns-role"
}
