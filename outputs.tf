output "guacamole_url" {
  value       = local.guac_url
  description = "URL of Guacamole instance"
}

output "guacamole_sg_id" {
  value       = aws_security_group.guacamole.id
  description = "ID of security group which allows communication with Guacamole instance"
}
