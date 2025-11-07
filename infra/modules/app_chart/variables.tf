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
