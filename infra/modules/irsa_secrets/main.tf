data "aws_eks_cluster" "this" { name = var.cluster_name }

# Secret ARN can vary by driver, account for truncated and full ARN
locals {
  oidc            = replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
  arn_last6       = substr(var.secret_arn, max(0, length(var.secret_arn) - 6), 6)
  arn_suffix7     = "-${local.arn_last6}"
  secret_arn_base = trimsuffix(var.secret_arn, local.arn_suffix7)
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "${local.oidc}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_policy" "allow_get" {
  name = "${var.role_name}-asm"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:ListSecretVersionIds"
        ]
        # Allow both the base secret ARN and all versioned ARNs.
        Resource = [
          local.secret_arn_base,
          "${local.secret_arn_base}-*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.allow_get.arn
}
