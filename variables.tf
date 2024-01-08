variable "guacadmin_password" {
  description = "Password for guacadmin user (a new random salt will be generated)."
  type        = string
  sensitive   = true
}

variable "public_subnets" {
  description = "Subnets to place load balancer in."
  type        = list(string)
}

variable "private_subnets" {
  description = "Subnets to place Fargate and Aurora in."
  type        = list(string)
}

variable "guacamole_task_security_groups" {
  description = "IDs of security groups to attach to Guacamole ECS task."
  type        = list(string)
  default     = []
}

variable "use_http_only" {
  description = "Whether to use HTTP only for load balancer (should just be for evaluating the module and automated tested)."
  type        = bool
  default     = false
}

variable "hosted_zone_name" {
  description = "If provided, will create DNS record in this hosted zone for load balancer. Not used if `use_http_only` is true."
  type        = string
  default     = ""
}

variable "subdomain" {
  description = "Subdomain within hosted zone to create DNS record for load balancer. Not used if `use_http_only` is true. If not provided, Guacamole URL will be for base hosted zone."
  type        = string
  default     = ""
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip final snapshot when Aurora DB is destroyed"
  type        = bool
  default     = true
}

variable "maximum_guacamole_task_count" {
  description = "Maximum number of Guacamole tasks to run at once (for autoscaling). Minimum number of tasks is always 1."
  type        = number
  default     = 10
}

variable "guacamole_task_environment_vars" {
  description = "Environment variables to pass to Guacamole task (database environment variables are automatically passed). Should be list of dictionaries with keys `name` and `value`."
  type        = list(map(string))
  default     = []
}

variable "guac_image_uri" {
  description = "ARN of custom Guacamole image to use. If not provided, will use latest version of `guacamole/guacamole`."
  type        = string
  default     = ""
}

variable "enable_cloudwatch_insights" {
  description = "Whether to enable CloudWatch Insights for Guacamole ECS cluster."
  type        = bool
  default     = false
}
