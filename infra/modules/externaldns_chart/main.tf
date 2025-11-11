resource "kubernetes_service_account" "sa" {
  metadata {
    name      = var.sa_name
    namespace = var.namespace
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
    name  = "sources"
    value = "{ingress,service}"
  }

  set_list {
    name  = "domainFilters"
    value = var.domain_filters
  }

  set_list {
    name  = "zoneIdFilters"
    value = var.zone_id_filters
  }
}
