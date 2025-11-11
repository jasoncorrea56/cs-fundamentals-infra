data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  oidc_url      = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_hostpath = replace(local.oidc_url, "https://", "")
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # Strictly bind to the ExternalDNS ServiceAccount in kube-system
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_hostpath}:sub"
      values = [
        "system:serviceaccount:${var.namespace}:${var.sa_name}"
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_policy" "dns" {
  name = "${var.role_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.dns.arn
}
