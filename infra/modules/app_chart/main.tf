resource "helm_release" "app" {
  name       = var.release_name
  namespace  = var.namespace
  repository = null
  chart      = var.chart_path
  version    = null

  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 300

  values = [
    file(var.values_file)
  ]

  # Existing image overrides passthrough
  dynamic "set" {
    for_each = var.image_overrides
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  # Inject ACM cert ARN into Ingress annotations when provided.
  # Note: dots in the annotation key are escaped for Helm set syntax.
  dynamic "set" {
    for_each = var.acm_certificate_arn != "" ? [1] : []
    content {
      name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
      value = var.acm_certificate_arn
    }
  }

  # Note: depends_on handled by caller.
}
