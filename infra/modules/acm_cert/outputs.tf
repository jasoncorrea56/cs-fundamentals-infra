output "certificate_arn" {
  value       = aws_acm_certificate.this.arn
  description = "ACM certificate ARN (may be PENDING_VALIDATION)"
}
