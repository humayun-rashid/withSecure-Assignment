output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for s in aws_subnet.private : s.id]
}

output "endpoints_sg_id" {
  description = "Security Group ID for VPC Endpoints"
  value       = aws_security_group.endpoints.id
}

output "public_route_table_id" {
  description = "Route Table ID for public subnets"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "Route Table ID for private subnets"
  value       = aws_route_table.private.id
}
