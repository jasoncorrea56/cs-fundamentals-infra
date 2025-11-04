provider "aws" {
  alias  = "acm"
  region = var.region
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.hosted_zone_id
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

# Only wait when explicitly enabled
resource "aws_acm_certificate_validation" "this" {
  count                   = var.enable_validation ? 1 : 0
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}
