variable "app_name" {
  description = "Name of the app being hosted (i.e. cs-fundamentals)"
  type        = string
}

variable "app_namespace" {
  description = "Namespace for the app being hosted (i.e. csf)"
  type        = string
}

variable "github_repo" {
  description = "Github repo for the app (i.e. cs-fundamentals)"
  type        = string
}

variable "github_owner" {
  description = "Owner of the Github repo (i.e. jasoncorrea56)"
  type        = string
}
