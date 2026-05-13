output "vpc_id" {
  value       = aws_vpc.devops_vpc.id
  description = "El ID de la VPC creada"
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet.id
  description = "El ID de la subred pública"
}
output "server_public_ip" {
  value       = aws_instance.devops_server.public_ip
  description = "La dirección IP pública de tu servidor DevOps"
}

output "server_dns" {
  value       = aws_instance.devops_server.public_dns
  description = "El nombre DNS público del servidor"
}