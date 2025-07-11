variable "guacadmin_password" {
  description = "Password for guacadmin user (a new random salt will be generated)."
  default     = "guacadmin"
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

variable "disable_database" {
  description = "If true, will not create an Aurora database for Guacamole. Can be cost-efficient if not using JDBC auth plugin. If true, none of the other database variables are used."
  type        = bool
  default     = false
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

variable "db_instance_count" {
  description = "Number of Aurora instances to create (if you need read replicas)."
  type        = number
  default     = 1
}

variable "db_min_capacity" {
  description = "Minimum capacity AUC for Aurora DB."
  type        = number
  default     = 0.5
}

variable "db_max_capacity" {
  description = "Maximum capacity AUC for Aurora DB."
  type        = number
  default     = 2.0
}

variable "db_auto_pause" {
  description = "Seconds after which to automatically pause the database (only applies if db_min_capacity is 0.0)."
  type        = number
  default     = 3600
}

variable "seconds_until_auto_pause" {
  description = "Number of seconds of inactivity before database is automatically paused."
  type        = number
  default     = 300
}

variable "enable_nlb_logging" {
  description = "Whether to enable logging for the NLB."
  type        = bool
  default     = false
}

variable "efs_tags" {
  description = "Tags to apply to EFS instance."
  type        = map(string)
  default     = {}
}

variable "guacamole_task_cpu" {
  description = "Number of vCPU to allocate to Guacamole task. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html."
  type        = number
  default     = 1024
}

variable "guacamole_task_memory" {
  description = "Amount of memory in MiB to allocate to Guacamole task. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html."
  type        = number
  default     = 2048
}

variable "cidr_allow_list" {
  description = "List of IP address ranges (CIDRs) to allow access to Guacamole. All other IP addresses will be blocked. If a single IP, write like `1.1.1.1/32`."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "health_check_path" {
  description = "Path to use for health check."
  type        = string
  default     = "/guacamole/"
}
