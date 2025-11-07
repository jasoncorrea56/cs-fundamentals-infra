resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.chart_version

  namespace        = var.namespace
  create_namespace = false

  # Conservative, EKS-friendly defaults. Avoid insecure TLS unless needed.
  values = [
    yamlencode({
      args = [
        "--kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS",
      ]
      # Increase to 2 later if you want HA for control-plane maintenance windows.
      replicas = 1
    })
  ]
}
