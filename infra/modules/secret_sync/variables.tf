variable "namespace" { type = string }
variable "region" { type = string }
variable "app_sa" { type = string }          # App service account
variable "role_arn" { type = string }        # i.e. module.irsa_db.role_arn
variable "spc_name" { type = string }        # i.e. <app_namespace>-db-spc
variable "k8s_secret_name" { type = string } # i.e. <app_namespace>-db
variable "secret_arn" {
  description = "Full ARN of the AWS Secrets Manager secret (i.e. from module.db_secret.arn)."
  type        = string
}
