resource "helm_release" "aws_provider" {
  name       = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"

  atomic          = true
  cleanup_on_fail = true
  wait            = true

  set {
    name  = "fullnameOverride"
    value = "csi-provider-aws"
  }
}
