variable "release_name" {
  type        = string
  description = "Helm release name"
  default     = "csf"
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace to deploy into"
  default     = "csf"
}

variable "enable" {
  description = "Whether to install/manage the app Helm release from this module"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Logical environment name (dev, qa, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "chart_path" {
  type        = string
  description = "Path to the app Helm chart directory"
}

variable "values_file" {
  type        = string
  description = "Path to the prod values file for the chart"
}

variable "image_overrides" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Optional list of helm set overrides for image repo/tag, etc."
  default     = []
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for ALB HTTPS. If empty, no override is set"
  default     = ""
}

variable "ingress_hosts" {
  description = "List of ingress hostnames for this environment"
  type        = list(string)
  default     = []
}
