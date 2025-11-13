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

  # 🔒 Disable CSI Secrets Store at the chart level (avoid mounting secrets-store.csi.k8s.io)
  set {
    name  = "secretsStore.enabled"
    value = "false"
  }

  # 🔒 Also ensure the chart doesn't try to manage its own K8s Secret
  # (we already have csf-db managed separately)
  set {
    name  = "secret.enabled"
    value = "false"
  }

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

  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.hosts[${set.key}].host"
      value = set.value
    }
  }

  # Ensure at least one path under each host
  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.hosts[${set.key}].paths[0].path"
      value = "/"
    }
  }

  dynamic "set" {
    for_each = var.ingress_hosts
    content {
      name  = "ingress.hosts[${set.key}].paths[0].pathType"
      value = "Prefix"
    }
  }
}
