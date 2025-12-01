resource "aws_iam_policy" "this" {
  name   = var.policy_name
  policy = file("${path.module}/policy.json")

  tags = merge(
    var.tags,
    {
      Name = var.policy_name
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = var.role_name
  policy_arn = aws_iam_policy.this.arn
}
