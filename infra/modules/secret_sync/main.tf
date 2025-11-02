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
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata   = { name = var.spc_name, namespace = var.namespace }
    spec = {
      provider = "aws"
      parameters = {
        objects = yamlencode([
          {
            objectName = "arn:aws:secretsmanager:us-west-2:948319129176:secret:csf/db-url-GUR3Uh"
            objectType = "secretsmanager"
            region     = var.region
            jmesPath   = [{ path = "db_url", objectAlias = "db_url" }]
          }
        ])
      }
      secretObjects = [{
        secretName = var.k8s_secret_name
        type       = "Opaque"
        data       = [{ objectName = "db_url", key = "DB_URL" }]
      }]
    }
  }
  depends_on = [kubernetes_service_account.app]
}
