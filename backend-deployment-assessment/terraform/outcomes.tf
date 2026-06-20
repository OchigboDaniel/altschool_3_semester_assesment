output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB — use this to access the app"
  value       = aws_lb.main.dns_name
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion host — SSH entry point"
  value       = aws_eip.bastion.public_ip
}

output "backend_private_ip" {
  description = "Private IP of the Backend EC2 instance"
  value       = aws_instance.backend.private_ip
}

output "mongodb_private_ip" {
  description = "Private IP of the MongoDB EC2 instance"
  value       = aws_instance.mongodb.private_ip
}