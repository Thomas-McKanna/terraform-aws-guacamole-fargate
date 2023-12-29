variable "hosted_zone_name" {
  description = "Name of hosted zone to create DNS record in"
  type        = string
}

variable "guacadmin_password" {
  description = "Password for guacadmin user"
  type        = string
  sensitive   = true
}

variable "certificate_arn" {
  description = "Certificate to use for load balancer HTTPS"
  type        = string
}

variable "public_subnets" {
  description = "Subnets to place load balancer in"
  type        = list(string)
}

variable "private_subnets" {
  description = "Subnets to place Fargate and Aurora in"
  type        = list(string)
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip final snapshot when Aurora DB is destroyed"
  type        = bool
  default     = true
}
