output "hello-weold" {
  value       = "Hello World"
  sensitive   = true
  description = "Print hello world"
}

output "vpc_id" {
  description = "print VPC ID"
  value       = aws_vpc.vpc.id
  sensitive   = true
}

output "public_url" {
  description = "Public URL of our webserver"
  value       = "https://${aws_instance.web_server.private_ip}:8080/index.html"
}

output "vpc_info" {
  description = "info on VPC and env"
  value       = "Your ${aws_vpc.vpc.tags.Environment} VPC has ID as ${aws_vpc.vpc.id}"
}

output "Instace_ip" {
  value = aws_instance.web_server.public_ip
}


