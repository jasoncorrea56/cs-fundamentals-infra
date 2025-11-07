resource "helm_release" "app" {
  name       = var.release_name
  namespace  = var.namespace
  repository = null
  chart      = var.chart_path # local chart path (relative to this repo checkout)
  version    = null

  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 300

  # Feed the chart its prod values file (lives in the app repo)
  values = [
    file(var.values_file)
  ]

  # Optionally override image tag/repo without touching values files
  dynamic "set" {
    for_each = var.image_overrides
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  # If your chart depends on CRDs or other resources, wire them via depends_on in the caller.
}
