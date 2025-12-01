variable "name_prefix" {
  type        = string
  description = "Prefix for the ALB security group name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ALB lives"
}

variable "allowed_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the ALB (i.e. office/home/VPN IPs)"
}

variable "tags" {
  description = "Base tags to apply to resources in this module"
  type        = map(string)
  default     = {}
}
