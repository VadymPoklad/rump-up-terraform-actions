output "ec2_instance_ids" {
  description = "ID EC2"
  value       = [for instance in aws_instance.web_server : instance.id]
}

output "alb_dns_name" {
  description = "DNS name ALB"
  value       = aws_lb.application_load_balancer.dns_name
}