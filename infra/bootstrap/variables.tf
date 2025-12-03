variable "org" {
  type        = string
  default     = "jasoncorrea56"
  description = "GitHub organization or user that owns the repos using this bootstrap configuration"
}

variable "project" {
  type        = string
  default     = "cs-fundamentals"
  description = "Project slug used for naming AWS resources created during bootstrap (i.e. IAM roles, policies, state buckets)"
}

variable "env" {
  type        = string
  default     = "bootstrap"
  description = "Environment identifier for bootstrap resources (i.e. 'bootstrap')"
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region where bootstrap resources such as S3 backend and DynamoDB locks are created"
}

variable "owner" {
  type        = string
  default     = "Jason"
  description = "Owner tag applied to bootstrap resources for cost allocation and metadata clarity"
}
