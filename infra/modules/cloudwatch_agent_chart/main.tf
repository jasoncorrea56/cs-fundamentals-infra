resource "helm_release" "cloudwatch_agent" {
  name       = "aws-cloudwatch-metrics"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = var.chart_version

  namespace        = var.namespace
  create_namespace = true

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "cloudwatch-agent"
        annotations = {
          "eks.amazonaws.com/role-arn" = var.role_arn
        }
      }
      clusterName = var.cluster_name
      # Turn on Container Insights for EKS
      containerInsights = {
        enabled     = true
        clusterName = var.cluster_name
      }
    })
  ]
}
