data "aws_iam_openid_connect_provider" "this" {
  arn = var.oidc_provider_arn
}

locals {
  sa_sub   = "system:serviceaccount:${var.namespace}:${var.service_account}"
  oidc_url = replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "this" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Federated = data.aws_iam_openid_connect_provider.this.arn },
      Action    = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${local.oidc_url}:sub" = local.sa_sub
        }
      }
    }]
  })

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}

# Least-privileged policy for CloudWatch Agent Container Insights (metrics + infra describes)
resource "aws_iam_role_policy" "cwagent_inline" {
  name = "${var.role_name}-policy"
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # CloudWatch metrics
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
        Condition = {
          "StringEquals" : {
            "cloudwatch:namespace" : "ContainerInsights"
          }
        }
      },
      # Logs: create group/stream + put events if agent emits events
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      # Resource describes
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "eks:DescribeCluster",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}
