resource "helm_release" "aws_for_fluent_bit" {
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = var.chart_version

  namespace        = var.namespace
  create_namespace = true

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "aws-for-fluent-bit"
        annotations = {
          "eks.amazonaws.com/role-arn" = var.role_arn
        }
      }
      cloudWatch = {
        enabled         = true
        region          = var.region
        logGroupName    = "/aws/containerinsights/${var.cluster_name}/application"
        logStreamPrefix = "fluentbit-"
        autoCreateGroup = true
      }
      parseLog = { enabled = true }
      fluentBit = {
        # Default input tail for container logs - tweak filters as needed
      }
    })
  ]
}
