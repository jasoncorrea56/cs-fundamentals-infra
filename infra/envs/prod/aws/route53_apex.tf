# #############################################
# # Optional apex A ALIAS to the app ALB
# # - Prefers explicit vars if provided
# # - Otherwise attempts data lookup by ALB name
# # - Skips creation if inputs are incomplete
# #############################################

# # Attempt ALB lookup by name when provided
# data "aws_lb" "csf_alb" {
#   count = length(var.alb_name) > 0 ? 1 : 0
#   name  = var.alb_name
# }

# # Choose the ALB DNS/zone from either explicit vars or data source
# locals {
#   resolved_alb_dns_name = length(var.alb_dns_name) > 0 ? var.alb_dns_name : (length(var.alb_name) > 0 && length(data.aws_lb.csf_alb) > 0 ? data.aws_lb.csf_alb[0].dns_name : "")
#   resolved_alb_zone_id  = length(var.alb_zone_id) > 0 ? var.alb_zone_id : (length(var.alb_name) > 0 && length(data.aws_lb.csf_alb) > 0 ? data.aws_lb.csf_alb[0].zone_id : "")
#   apex_alias_enabled    = false # Only alias <app_namespace>.<domain> - uncomment below to alias the domain apex
#   # apex_alias_enabled    = var.enable_apex_alias && length(local.resolved_alb_dns_name) > 0 && length(local.resolved_alb_zone_id) > 0
# }

# # NOTE: ExternalDNS may manage <app_namespace>.<zone_name>.
# # These records make routing deterministic independent of controller timing.

# # 1) Apex (root) -> ALB (optional, guarded by enable_apex_alias)
# resource "aws_route53_record" "apex_domain" {
#   count = local.apex_alias_enabled ? 1 : 0

#   zone_id = module.route53_zone.zone_id
#   name    = var.zone_name
#   type    = "A"

#   alias {
#     name                   = local.resolved_alb_dns_name
#     zone_id                = local.resolved_alb_zone_id
#     evaluate_target_health = false
#   }
# }

# # 2) <app_namespace>.<zone_name> -> ALB (always created when ALB is resolvable)
# resource "aws_route53_record" "csf_app" {
#   count = length(local.resolved_alb_dns_name) > 0 && length(local.resolved_alb_zone_id) > 0 ? 1 : 0

#   zone_id = module.route53_zone.zone_id
#   name    = "${var.app_namespace}.${var.zone_name}"
#   type    = "A"

#   alias {
#     name                   = local.resolved_alb_dns_name
#     zone_id                = local.resolved_alb_zone_id
#     evaluate_target_health = false
#   }
# }
