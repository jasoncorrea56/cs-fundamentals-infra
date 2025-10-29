resource "aws_iam_openid_connect_provider" "github" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list  = ["sts.amazonaws.com"]
    thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "assume" {
    statement {
        actions = ["sts:AssumeRoleWithWebIdentity"]
        principals {
            type = "Federated"
            identifiers = [aws_iam_openid_connect_provider.github.arn]
        }
        condition {
            test = "StringEquals"
            variable = "token.actions.githubusercontent.com:aud"
            values = ["sts.amazonaws.com"]
        }
        condition {
            test = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values = ["repo:${var.github_org}/${var.github_repo}:${var.github_ref}"]
        }
    }
}

resource "aws_iam_role" "gh_ecr_push" {
  name               = "github-oidc-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "ecr_push" {
    statement {
        actions   = ["ecr:GetAuthorizationToken"]
        resources = ["*"]
    }
    statement {
        actions = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart",
            "ecr:BatchGetImage",
            "ecr:DescribeRepositories",
            "ecr:DescribeImages",
        ]
        resources = [var.ecr_arn]
    }
}

resource "aws_iam_policy" "ecr_push" {
    name   = "ecr-push-csf"
    policy = data.aws_iam_policy_document.ecr_push.json
}
resource "aws_iam_role_policy_attachment" "attach" {
    role       = aws_iam_role.gh_ecr_push.name
    policy_arn = aws_iam_policy.ecr_push.arn
}

output "role_arn" {
    value = aws_iam_role.gh_ecr_push.arn
}
