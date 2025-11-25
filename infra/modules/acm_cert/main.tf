provider "aws" {
  alias  = "acm"
  region = var.region
}

resource "aws_acm_certificate" "this" {
  provider                  = aws.acm
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = var.subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = var.enable_validation ? {
    # Group domain_validation_options by resource_record_name.
    # This prevents duplicate key errors when multiple domains
    # (i.e. wildcard + apex) share the same ACM validation CNAME.
    for dvo in aws_acm_certificate.this.domain_validation_options :
    dvo.resource_record_name => dvo...
  } : {}

  zone_id = var.hosted_zone_id

  # each.value is now a list of dvo objects (grouped by record name).
  # They are functionally identical, so we use the first one.
  name            = each.value[0].resource_record_name
  type            = each.value[0].resource_record_type
  ttl             = 60
  records         = [each.value[0].resource_record_value]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  count                   = var.enable_validation ? 1 : 0
  provider                = aws.acm
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

