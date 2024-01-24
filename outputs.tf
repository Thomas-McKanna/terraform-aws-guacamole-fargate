output "guacamole_url" {
  value       = local.guac_url
  description = "URL of Guacamole instance"
}

output "guacamole_sg_id" {
  value       = aws_security_group.guacamole.id
  description = "ID of security group which allows communication with Guacamole instance"
}

output "alb_logging_bucket" {
  value       = var.enable_alb_logging ? aws_s3_bucket.alb_logging[0].id : null
  description = "Name of S3 bucket which stores ALB logs (requires setting enable_alb_logging to true)"
}
