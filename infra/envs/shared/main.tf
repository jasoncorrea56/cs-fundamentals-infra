# Shared public hosted zone for jasoncorrea.dev
resource "aws_route53_zone" "jasoncorrea" {
  name          = "jasoncorrea.dev"
  comment       = "Shared public hosted zone for jasoncorrea.dev"
  force_destroy = true
}
