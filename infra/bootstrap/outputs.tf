output "tfstate_bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "tf_locks_table" {
  value = aws_dynamodb_table.tf_locks.name
}

output "terraform_role_arn" {
  value = aws_iam_role.terraform_operator.arn
}
