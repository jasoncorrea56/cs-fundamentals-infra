variable "namespace" {
  type        = string
  description = "Namespace to install metrics-server into"
  default     = "kube-system"
}

variable "chart_version" {
  type        = string
  description = "Chart version for metrics-server (optional pin)"
  default     = null
}
