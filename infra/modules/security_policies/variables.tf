variable "namespace" {
  description = "Target namespace for policies and RBAC"
  type        = string
}

variable "app_selector" {
  description = "Label selector that matches the app pods (key/value)"
  type = object({
    key   = string
    value = string
  })
}

variable "service_account" {
  description = "Name of service account the app runs under"
  type        = string
}

variable "allow_db_egress" {
  description = "Allow DB egress? If true, opens TCP port(s) to the provided CIDRs"
  type = object({
    enabled = bool
    cidrs   = list(string)
    ports   = list(number) # [5432]
  })
  default = {
    enabled = false
    cidrs   = []
    ports   = []
  }
}

variable "allow_https_egress" {
  description = "Allow HTTPS egress to the internet (0.0.0.0/0) for SDKs, APIs, etc."
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

variable "ingress_cidrs" {
  description = "CIDRs allowed to reach the app (i.e., VPC CIDR for ALB target-type=ip)"
  type        = list(string)
  default     = []
}

variable "app_port" {
  description = "Container port exposed by the app"
  type        = number
  default     = 8080
}

variable "manage_namespace" {
  type        = bool
  default     = true
  description = "If false, do not create/delete the Namespace - assume it's managed elsewhere"
}
