resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  recovery_window_in_days = 0

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "v" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({ db_url = var.db_url })
}
