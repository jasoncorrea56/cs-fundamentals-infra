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
    metadata   = { name = var.spc_name, namespace = var.namespace }
    spec = {
      provider = "aws"
      parameters = {
        objects = yamlencode([
          {
            objectName = var.secret_arn
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
