variable "cluster_name" { type = string }
variable "oidc_provider_arn" { type = string }
variable "namespace" { type = string }
variable "service_account" { type = string }
variable "role_name" { type = string }

variable "tags" {
  description = "Base tags to apply to resources in this module"
  type        = map(string)
  default     = {}
}
