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
  description = "Whether to skip final snapshot when Aurora DB is destroyed."
  type        = bool
  default     = true
}

variable "db_enable_deletion_protection" {
  description = "Whether to enable deletion protection for Aurora DB."
  type        = bool
  default     = false
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

variable "enable_session_recording" {
  description = "If true, sessions will be recorded and stored in an AWS Elastic File System (EFS) instance."
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "If true, will enable the use of execute_command on the ECS tasks (useful for debugging)."
  type        = bool
  default     = false
}

variable "log_level" {
  description = "Log level for Guacamole."
  type        = string
  default     = "info"
}

variable "auto_pause_database" {
  description = "Whether to automatically pause the database when not in use (this is a feature of Serverless RDS)."
  type        = bool
  default     = true
}

variable "seconds_until_auto_pause" {
  description = "Number of seconds of inactivity before database is automatically paused."
  type        = number
  default     = 300
}

variable "enable_alb_logging" {
  description = "Whether to enable logging for the ALB."
  type        = bool
  default     = false
}

variable "enable_brute_force_protection" {
  description = "If enabled, will create Web Application Firewall (WAF) rules to block brute force attacks."
  type        = bool
  default     = true
}

variable "brute_force_allow_list" {
  description = "List of CIDRs to always allow through WAF. If a single IP, write like `1.2.3.4/32`."
  type        = list(string)
  default     = []
}

variable "efs_tags" {
  description = "Tags to apply to EFS instance."
  type        = map(string)
  default     = {}
}

variable "cors_allowed_origin" {
  description = "Origin to allow for CORS requests to `/guacamole/api/tokens`. If not provided, will not set CORS header."
  type        = string
  default     = ""
}

variable "guacamole_task_cpu_cores" {
  description = "Number of CPU cores to allocate to Guacamole task."
  type        = number
  default     = 1
}

variable "guacamole_task_memory_megabytes" {
  description = "Amount of memory in MB to allocate to Guacamole task."
  type        = number
  default     = 2048
}
