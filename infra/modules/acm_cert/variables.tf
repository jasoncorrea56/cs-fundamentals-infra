variable "domain_name" {
  description = "Primary FQDN (i.e. csf.jasoncorrea.dev)"
  type        = string
}

variable "subject_alternative_names" {
  description = "Optional SANs"
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID to create DNS validation records in"
  type        = string
}

variable "region" {
  description = "Region for the certificate (must match ALB region)"
  type        = string
  default     = "us-west-2"
}

variable "enable_validation" {
  description = "Whether to wait for ACM DNS validation (hangs until domain is delegated)"
  type        = bool
  default     = false
}
