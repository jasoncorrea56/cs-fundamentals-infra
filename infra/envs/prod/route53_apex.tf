data "aws_lb" "csf_alb" {
  # Match the ALB created by the AWS Load Balancer Controller for the csf ingress
  name = "k8s-csf-csfcsfun-145ebc3211"
}

resource "aws_route53_record" "apex_domain" {
  zone_id = module.route53_zone.zone_id
  name    = var.zone_name
  type    = "A"

  alias {
    name                   = data.aws_lb.csf_alb.dns_name
    zone_id                = data.aws_lb.csf_alb.zone_id
    evaluate_target_health = false
  }
}
