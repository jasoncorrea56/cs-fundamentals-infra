variable "cluster_name" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "cluster_role_arn" { type = string }
variable "node_role_arn" { type = string }
variable "kubernetes_version" {
  type    = string
  default = "1.33"
}
