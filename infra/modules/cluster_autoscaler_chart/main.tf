# Helm install (official autoscaler helm repo)
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.chart_version

  namespace        = var.namespace
  create_namespace = true

  values = [
    yamlencode({
      image = {
        repository = "registry.k8s.io/autoscaling/cluster-autoscaler"
        tag        = "v1.34.0"
      }
    })
  ]

  # Create SA and annotate with the IRSA role
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = var.sa_name
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.role_arn
  }

  # Auto-discovery by cluster name (matches your nodegroup tags)
  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  # Region and some safe defaults
  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "10m"
  }
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "resources.requests.memory"
    value = "150Mi"
  }
  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }
  set {
    name  = "resources.limits.memory"
    value = "300Mi"
  }
}
