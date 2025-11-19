output "shared_zone_id" {
  description = "Hosted zone ID for jasoncorrea.dev"
  value       = aws_route53_zone.jasoncorrea.zone_id
}

output "shared_zone_name" {
  description = "Hosted zone name for jasoncorrea.dev"
  value       = aws_route53_zone.jasoncorrea.name
}
