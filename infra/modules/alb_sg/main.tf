resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-sg"
  description = "ALB security group for ${var.name_prefix}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  # Optionally open port 443 if TLS enabled on dev
  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = var.allowed_cidrs
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.name_prefix}-sg"
    Component = "alb"
  }
}
