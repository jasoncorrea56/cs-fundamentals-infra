resource "aws_secretsmanager_secret" "this" {
  name = var.name

  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_secretsmanager_secret_version" "v" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({ db_url = var.db_url })
}
