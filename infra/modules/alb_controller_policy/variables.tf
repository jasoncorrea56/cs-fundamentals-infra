variable "policy_name" { type = string }
variable "role_name" { type = string }

variable "tags" {
  description = "Base tags to apply to resources in this module"
  type        = map(string)
  default     = {}
}
