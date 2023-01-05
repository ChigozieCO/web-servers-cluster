output "alb-dns-name" {
  description = "This is the Domain name of the load balancer."
  value       = aws_lb.server2-lb.dns_name
}