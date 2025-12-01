variable "name" { type = string }
variable "cidr_block" { type = string }
variable "cluster_name" { type = string }
variable "azs" { type = list(string) }

variable "environment" {
  description = "Logical environment name (dev, qa, prod, etc.)"
  type        = string
}

variable "tags" {
  description = "Base tags to apply to resources in this module"
  type        = map(string)
  default     = {}
}
