output "server2-publicIP" {
  description = "This is the public IP address of the web server."
  value       = aws_instance.server2.public_ip

}