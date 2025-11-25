resource "helm_release" "csi_driver" {
  name       = "secrets-store-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"

  atomic          = true
  cleanup_on_fail = true
  wait            = true

  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "syncSecret.enabled"
    value = "true"
  }
  set {
    name  = "enableSecretRotation"
    value = "true"
  }
}
