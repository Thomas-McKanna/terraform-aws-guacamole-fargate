output "guacamole_url" {
  value       = "https://guac.${var.hosted_zone_name}"
  description = "URL of Guacamole instance"
}
