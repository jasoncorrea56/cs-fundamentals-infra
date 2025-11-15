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

############################################################
# Runtime Ops: Minimal alerting via CloudWatch.
#
# Design:
# - Discover the ALB created by the AWS Load Balancer
#   Controller using elbv2.k8s.aws/cluster = <clusterName>.
# - Use ContainerInsights metrics for pod restart alarms.
# - Alarms are only created when enable_runtime_alerts = true
#   to avoid failing plans before the ALB exists.
############################################################

# SNS topic for runtime alerts (attach subscriptions out-of-band if you want email/slack)
resource "aws_sns_topic" "runtime_alerts" {
  name = "${module.eks.cluster_name}-runtime-alerts"
}

# Optional email subscription for runtime alerts.
# If runtime_alert_email is non-empty, create a subscription.
resource "aws_sns_topic_subscription" "runtime_alert_email" {
  count = var.runtime_alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.runtime_alerts.arn
  protocol  = "email"
  endpoint  = var.runtime_alert_email
}

# Look up the Application Load Balancer created by the AWS Load Balancer Controller.
# We match on:
# - elbv2.k8s.aws/cluster = cluster name (set by the controller)
#
# This assumes a single ALB per cluster/app.
data "aws_lb" "app" {
  count = var.enable_runtime_alerts ? 1 : 0

  tags = {
    "elbv2.k8s.aws/cluster" = module.eks.cluster_name
  }
}

# Alarm 1: high rate of 5xx responses from ALB targets (AWS/ApplicationELB).
# Minimal but real: if >=5 5xxs in 5 minutes, alarm.
resource "aws_cloudwatch_metric_alarm" "alb_target_5xx_high" {
  count = var.enable_runtime_alerts ? 1 : 0

  alarm_name        = "${module.eks.cluster_name}-alb-target-5xx-high"
  alarm_description = "High rate of HTTP 5xx responses from targets behind the ALB for ${module.eks.cluster_name} (cs-fundamentals)."

  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = data.aws_lb.app[0].arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.runtime_alerts.arn
  ]

  tags = {
    Name        = "${module.eks.cluster_name}-alb-target-5xx-high"
    Environment = "prod"
    Service     = "cs-fundamentals"
  }
}

# Alarm 2: high p95 latency from ALB targets.
# If p95 TargetResponseTime > 0.75s for 5 minutes, alarm.
resource "aws_cloudwatch_metric_alarm" "alb_target_latency_p95_high" {
  count = var.enable_runtime_alerts ? 1 : 0

  alarm_name        = "${module.eks.cluster_name}-alb-target-latency-p95-high"
  alarm_description = "High p95 TargetResponseTime for ALB targets behind ${module.eks.cluster_name} (cs-fundamentals)."

  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic  = "p95"
  period              = 60
  evaluation_periods  = 5
  threshold           = 0.75
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = data.aws_lb.app[0].arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.runtime_alerts.arn
  ]

  tags = {
    Name        = "${module.eks.cluster_name}-alb-target-latency-p95-high"
    Environment = "prod"
    Service     = "cs-fundamentals"
  }
}

# Alarm 3: excessive pod/container restarts in the csf namespace.
#
# Uses ContainerInsights metric:
#   pod_number_of_container_restarts
# Dimensions:
#   Namespace = "csf"
#   ClusterName = <clusterName>
#
# If the sum of restarts across pods in the namespace exceeds 3
# over a 10-minute window, we alert.
resource "aws_cloudwatch_metric_alarm" "pod_restarts_high" {
  count = var.enable_runtime_alerts ? 1 : 0

  alarm_name        = "${module.eks.cluster_name}-pod-restarts-high"
  alarm_description = "High number of container restarts across pods in the 'csf' namespace for ${module.eks.cluster_name}."

  namespace           = "ContainerInsights"
  metric_name         = "pod_number_of_container_restarts"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 10
  threshold           = 3
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = module.eks.cluster_name
    Namespace   = "csf"
  }

  alarm_actions = [
    aws_sns_topic.runtime_alerts.arn
  ]

  tags = {
    Name        = "${module.eks.cluster_name}-pod-restarts-high"
    Environment = "prod"
    Service     = "cs-fundamentals"
  }
}
