output "tfstate_bucket" {
  value = aws_s3_bucket.tfstate.bucket
}

output "tf_locks_table" {
  value = aws_dynamodb_table.tf_locks.name
}
