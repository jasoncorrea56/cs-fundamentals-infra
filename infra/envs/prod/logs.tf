
resource "aws_cloudwatch_log_group" "ci_app" {
  name              = "/aws/containerinsights/${module.eks.cluster_name}/application"
  retention_in_days = 3 # <7 to minimize costs
  lifecycle { prevent_destroy = false }
}

resource "aws_cloudwatch_log_group" "ci_perf" {
  name              = "/aws/containerinsights/${module.eks.cluster_name}/performance"
  retention_in_days = 3
  lifecycle { prevent_destroy = false }
}

resource "aws_cloudwatch_log_group" "ci_host" {
  name              = "/aws/containerinsights/${module.eks.cluster_name}/host"
  retention_in_days = 3
  lifecycle { prevent_destroy = false }
}

# Control plane logs (if enabled) commonly land here
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${module.eks.cluster_name}/cluster"
  retention_in_days = 3
  lifecycle { prevent_destroy = false }
}
