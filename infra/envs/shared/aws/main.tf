locals {
  app_name     = var.app_name
  app_ns       = var.app_namespace
  github_owner = var.github_owner
  github_repo  = var.github_repo
}

# ------------------------------------------------------------
# Hosted Zone
# ------------------------------------------------------------

resource "aws_route53_zone" "jasoncorrea" {
  name          = "jasoncorrea.dev"
  comment       = "Shared public hosted zone for jasoncorrea.dev"
  force_destroy = true
}

# ------------------------------------------------------------
# GitHub Actions OIDC Provider
# ------------------------------------------------------------

# --- GitHub OIDC provider (GHA -> AWS) --- #
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# ------------------------------------------------------------
# GitHub Deployer Role
# ------------------------------------------------------------

data "aws_iam_policy_document" "gha_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only allow tokens from your repo (all branches/tags)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_owner}/${local.github_repo}:*"]
    }
  }
}


resource "aws_iam_role" "gha_deployer" {
  name               = "${local.app_ns}-github-deployer"
  assume_role_policy = data.aws_iam_policy_document.gha_assume_role.json
}

# ------------------------------------------------------------
# GitHub Deployer Permissions
# ------------------------------------------------------------

data "aws_iam_policy_document" "gha_permissions" {
  statement {
    sid = "EcrPush"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:ListImages"
    ]
    resources = ["*"]
  }

  statement {
    sid = "EksDescribe"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gha_deployer" {
  name   = "${local.app_ns}-github-deployer-policy"
  policy = data.aws_iam_policy_document.gha_permissions.json
}

resource "aws_iam_role_policy_attachment" "gha_deployer_attach" {
  role       = aws_iam_role.gha_deployer.name
  policy_arn = aws_iam_policy.gha_deployer.arn
}

# ------------------------------------------------------------
# Shared ECR repository for cs-fundamentals
# ------------------------------------------------------------

module "ecr_csf" {
  source = "../../../modules/ecr"
  name   = local.app_name
}

# ------------------------------------------------------------
# Shared ACM wildcard certificate (*.jasoncorrea.dev)
# ------------------------------------------------------------

module "acm_csf" {
  source = "../../../modules/acm_cert"

  # Wildcard for all app environments (dev/prod/qa/etc.)
  domain_name = "*.${aws_route53_zone.jasoncorrea.name}"

  # Root domain SAN, mirroring the prod pattern
  subject_alternative_names = [
    aws_route53_zone.jasoncorrea.name,
  ]

  enable_validation = var.enable_acm_validation

  # Shared owns the hosted zone, so we reference it directly
  hosted_zone_id = aws_route53_zone.jasoncorrea.zone_id
  region         = "us-west-2"
}
