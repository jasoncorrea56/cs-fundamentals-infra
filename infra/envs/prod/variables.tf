variable "app_domain" {
  description = "FQDN for the app (i.e. csf.jasoncorrea.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID that owns app_domain"
  type        = string
  default     = ""
}

variable "db_url" {
  description = "Database connection URL"
  type        = string
  default     = ""
}

variable "zone_name" {
  description = "Hosted zone name (i.e. jasoncorrea.com.)"
  type        = string
  default     = null
}
