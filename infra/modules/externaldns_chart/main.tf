resource "kubernetes_service_account" "sa" {
  metadata {
    name        = var.sa_name
    namespace   = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.role_arn
    }
  }
}

resource "helm_release" "externaldns" {
  name       = "external-dns"
  namespace  = var.namespace
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  # version  = "1.15.0" # optional pin


  depends_on = [kubernetes_service_account.sa]

  set {
    name  = "provider"
    value = "aws"
  }
  set {
    name  = "policy"
    value = "sync"
  }
  set {
    name  = "registry"
    value = "txt"
  }
  set {
    name  = "txtOwnerId"
    value = var.owner_id
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = var.sa_name
  }
  set {
    name = "sources"
    value = "{ingress,service}"
  }

  # Optional scoping (use one or both)
  dynamic "set" {
    for_each = length(var.domain_filters) > 0 ? [1] : []
    content {
      name  = "domainFilters"
      value = join(",", var.domain_filters)
    }
  }
  dynamic "set" {
    for_each = length(var.zone_id_filters) > 0 ? [1] : []
    content {
      name  = "zoneIdFilters"
      value = join(",", var.zone_id_filters)
    }
  }
}
