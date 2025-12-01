resource "aws_route53_zone" "this" {
  name          = var.zone_name
  comment       = "Public hosted zone for ${var.zone_name}"
  force_destroy = true

  tags = merge(
    var.tags,
    {
      Name = var.zone_name
    }
  )
}
