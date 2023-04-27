output "public_ip_e" {
    value = aws_eip.eip_instance_e.public_ip
}

output "public_ip_f" {
    value = aws_eip.eip_instance_f.public_ip
}

output "load_balancer_dns" {
    value = aws_alb.my_app_alb.dns_name
}
