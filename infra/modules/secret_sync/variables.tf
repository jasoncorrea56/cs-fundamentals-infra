variable "namespace" { type = string }
variable "region" { type = string }
variable "app_sa" { type = string }          # i.e. csf-app
variable "role_arn" { type = string }        # i.e. module.irsa_db.role_arn
variable "spc_name" { type = string }        # i.e. csf-db-spc
variable "secret_name" { type = string }     # i.e. csf/db-url
variable "k8s_secret_name" { type = string } # i.e. csf-db
