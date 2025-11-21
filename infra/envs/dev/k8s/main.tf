locals {
  environment     = var.environment
  app_name        = var.app_name
  app_namespace   = var.app_namespace
  service_account = var.service_account
}

# K8s stack is currently empty; we'll gradually move
# kubernetes_* and helm_release resources here from aws/.
#
# This file intentionally defines no resources yet.
