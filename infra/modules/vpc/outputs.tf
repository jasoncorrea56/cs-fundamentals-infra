output "vpc_id" { value = aws_vpc.this.id }
output "public_subnets" { value = [for s in aws_subnet.public : s.id] }
output "private_subnets" { value = [for s in aws_subnet.private : s.id] }
output "cidr_block" {
  description = "Primary CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}
