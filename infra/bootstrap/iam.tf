data "aws_caller_identity" "current" {}

locals {
  terraform_role_name   = "${var.project}-terraform-operator"
  terraform_policy_name = "${var.project}-terraform-operator-policy"
}

data "aws_iam_policy_document" "terraform_operator_assume" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/tf-bootstrap",
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "terraform_operator" {
  name               = local.terraform_role_name
  assume_role_policy = data.aws_iam_policy_document.terraform_operator_assume.json

  tags = {
    Project = var.project
    Env     = var.env
    Owner   = var.owner
    Purpose = "terraform-operator"
  }
}

resource "aws_iam_policy" "terraform_operator" {
  name   = local.terraform_policy_name
  policy = file("${path.module}/terraform-operator-iam-policy.json")

  tags = {
    Project = var.project
    Env     = var.env
    Owner   = var.owner
    Purpose = "terraform-operator"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_operator_attach" {
  role       = aws_iam_role.terraform_operator.name
  policy_arn = aws_iam_policy.terraform_operator.arn
}
