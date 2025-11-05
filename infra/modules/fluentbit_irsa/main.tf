data "aws_iam_openid_connect_provider" "this" {
  arn = var.oidc_provider_arn
}

locals {
  sa_sub   = "system:serviceaccount:${var.namespace}:${var.service_account}"
  oidc_url = replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")
}

resource "aws_iam_role" "this" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Federated = data.aws_iam_openid_connect_provider.this.arn },
      Action    = "sts:AssumeRoleWithWebIdentity",
      Condition = { StringEquals = { "${local.oidc_url}:sub" = local.sa_sub } }
    }]
  })
}

# Minimal perms for Fluent Bit to ship logs to CloudWatch Logs
resource "aws_iam_role_policy" "fluentbit_inline" {
  name = "${var.role_name}-policy"
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["logs:CreateLogGroup"], Resource = "*" },
      { Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams", "logs:DescribeLogGroups"], Resource = "*" }
    ]
  })
}
