locals {
  csi_object_name = var.secret_arn
}

resource "kubernetes_service_account" "app" {
  metadata {
    name      = var.app_sa
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.role_arn
      "eks.amazonaws.com/audience" = "sts.amazonaws.com"
    }
  }
}

# SecretProviderClass (CRD) via kubernetes_manifest
resource "kubernetes_manifest" "spc" {
  count = var.enable ? 1 : 0

  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = var.spc_name
      namespace = var.namespace
    }
    spec = {
      provider = "aws"

      # Tell the AWS provider which Secrets Manager object to read
      # AND which JSON key to extract as an alias.
      parameters = {
        objects = <<-EOT
        - objectName: "${local.csi_object_name}"
          objectType: "secretsmanager"
          jmesPath:
            - path: "DB_URL"
              objectAlias: "DB_URL"
      EOT
      }

      # Enable "secret sync":
      # - Create/update a Kubernetes Secret named var.k8s_secret_name
      # - Populate key DB_URL from the ASM JSON field DB_URL
      secretObjects = [
        {
          secretName = var.k8s_secret_name
          type       = "Opaque"
          data = [
            {
              # MUST match the objectAlias above, not the ARN
              objectName = "DB_URL"
              key        = "DB_URL"
            }
          ]
        }
      ]
    }
  }
  depends_on = [kubernetes_service_account.app]
}

resource "kubernetes_secret_v1" "db" {
  count = var.enable ? 1 : 0

  metadata {
    name      = var.k8s_secret_name
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    DB_URL = "placeholder"
  }

  # CSI/ASM or manual writes can change the contents; TF just guarantees it exists.
  lifecycle {
    ignore_changes = [
      data,
    ]
  }
}
