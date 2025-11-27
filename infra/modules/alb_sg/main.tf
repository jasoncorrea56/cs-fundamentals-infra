resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-sg"
  description = "ALB security group for ${var.name_prefix}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [ingress]
  }

  tags = {
    Name      = "${var.name_prefix}-sg"
    Component = "alb"
  }
}
