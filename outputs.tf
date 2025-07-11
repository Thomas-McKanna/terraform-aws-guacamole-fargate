output "guacamole_url" {
  value       = local.guac_url
  description = "URL of Guacamole instance"
}

output "allow_guacamole_sg_id" {
  value       = aws_security_group.allow_guacamole_connection.id
  description = "ID of security group which allows Guacamole to connect to remote resources. Apply this to remote resources."
}

output "nlb_logging_bucket" {
  value       = var.enable_nlb_logging ? aws_s3_bucket.nlb_logging[0].id : null
  description = "Name of S3 bucket which stores NLB logs (requires setting enable_nlb_logging to true)"
}

output "recordings_efs_id" {
  value       = var.enable_session_recording ? aws_efs_file_system.guacamole_efs[0].id : null
  description = "ID of EFS file system which stores Guacamole recordings (requires setting enable_recording to true)"
}

output "recordings_efs_access_point_id" {
  value       = var.enable_session_recording ? aws_efs_access_point.guacamole_efs_access_point[0].id : null
  description = "ID of EFS access point which can be used to access Guacamole recordings (requires setting enable_recording to true)"
}

output "recordings_efs_access_security_group_id" {
  value       = var.enable_session_recording ? aws_security_group.recordings_efs_access[0].id : null
  description = "ID of security group which allows Guacamole to access EFS file system for recordings (requires setting enable_recording to true)"
}
