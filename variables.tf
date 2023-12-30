variable "guacadmin_password" {
  description = "Password for guacadmin user"
  type        = string
  sensitive   = true
}

variable "public_subnets" {
  description = "Subnets to place load balancer in"
  type        = list(string)
}

variable "private_subnets" {
  description = "Subnets to place Fargate and Aurora in"
  type        = list(string)
}

variable "guacamole_task_security_groups" {
  description = "IDs of security groups to attach to Guacamole ECS task"
  type        = list(string)
  default     = []
}

variable "use_http_only" {
  description = "Whether to use HTTP only for load balancer (should just be for evaluating the module and automated tested)"
  type        = bool
  default     = false
}

variable "hosted_zone_name" {
  description = "If provided, will create DNS record in this hosted zone for load balancer. This hosted zone name must be for the same zone as the certificate."
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain within hosted zone to create DNS record for load balancer."
  type        = string
  default     = ""
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip final snapshot when Aurora DB is destroyed"
  type        = bool
  default     = true
}

variable "maximum_guacamole_task_count" {
  description = "Maximum number of Guacamole tasks to run at once"
  type        = number
  default     = 10
}
