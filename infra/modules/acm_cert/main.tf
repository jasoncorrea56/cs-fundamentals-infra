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

  tags = merge(
    var.tags,
    {
      Name = replace(var.domain_name, "*", "wildcard")
    }
  )
}

# Turn ACM's set(domain_validation_options) into an indexable list
locals {
  dvo_list = tolist(aws_acm_certificate.this.domain_validation_options)
}

# Always create the Route53 validation record
resource "aws_route53_record" "validation" {
  zone_id = var.hosted_zone_id
  name    = local.dvo_list[0].resource_record_name
  type    = local.dvo_list[0].resource_record_type
  ttl     = 60

  records = [
    local.dvo_list[0].resource_record_value,
  ]
}

# Only wait for validation when enabled
resource "aws_acm_certificate_validation" "this" {
  count           = var.enable_validation ? 1 : 0
  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = [
    aws_route53_record.validation.fqdn,
  ]
}
