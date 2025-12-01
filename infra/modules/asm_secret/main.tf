resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  recovery_window_in_days = 0

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_secretsmanager_secret_version" "v" {
  secret_id = aws_secretsmanager_secret.this.id

  # Store as JSON with a DB_URL field so CSI/jmesPath can target it explicitly
  secret_string = jsonencode({
    DB_URL = var.db_url
  })
}
