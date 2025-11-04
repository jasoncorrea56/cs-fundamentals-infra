output "zone_id" {
  value       = aws_route53_zone.this.zone_id
  description = "Hosted zone ID"
}

output "name_servers" {
  value       = aws_route53_zone.this.name_servers
  description = "Authoritative NS you must set at your registrar"
}

output "zone_name" {
  value       = aws_route53_zone.this.name
  description = "Zone name"
}
