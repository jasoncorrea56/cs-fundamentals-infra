locals {
  oidc_url      = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_hostpath = replace(local.oidc_url, "https://", "")
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
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
      variable = "${local.oidc_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${local.oidc_hostpath}:sub"
      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}
