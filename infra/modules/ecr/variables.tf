variable "name" { type = string }

variable "tags" {
  description = "Base tags to apply to resources in this module"
  type        = map(string)
  default     = {}
}
