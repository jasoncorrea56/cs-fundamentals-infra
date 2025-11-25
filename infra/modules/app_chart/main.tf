resource "helm_release" "app" {
  # Allow callers (dev vs prod/qa/dr) to decide whether TF manages this release.
  # In dev you'll set enable = false so CI/CD owns the app.
  count = var.enable ? 1 : 0

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

  # Turn ingress on/off based on whether this env has any hosts configured.
  set {
    name  = "ingress.enabled"
    value = length(var.ingress_hosts) > 0 ? "true" : "false"
  }

  # Disable CSI Secrets Store at the chart level (avoid mounting secrets-store.csi.k8s.io)
  set {
    name  = "secretsStore.enabled"
    value = "false"
  }

  # Ensure the chart doesn't try to manage its own K8s Secret
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
  dynamic "set" {
    for_each = var.acm_certificate_arn != "" ? [1] : []
    content {
      name  = "ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
      value = var.acm_certificate_arn
    }
  }

  # Hosts per env (dev/qa/prod/dr). Empty list = no ingress.
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
