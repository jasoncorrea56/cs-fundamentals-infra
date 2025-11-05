
resource "aws_cloudwatch_log_group" "ci_app" {
  name              = "/aws/containerinsights/${module.eks.cluster_name}/application"
  retention_in_days = 3 # <7 to minimize costs
}

resource "aws_cloudwatch_log_group" "ci_perf" {
  name              = "/aws/containerinsights/${module.eks.cluster_name}/performance"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "ci_host" {
  name              = "/aws/containerinsights/${module.eks.cluster_name}/host"
  retention_in_days = 3
}
