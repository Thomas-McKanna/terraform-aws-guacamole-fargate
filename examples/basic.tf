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
  type    = list(string)
  default = ["subnet-05ed260b806c51c03", "subnet-07a56032c0cd3304e"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["subnet-059c12c1b12de438b", "subnet-057ca27e4dcd0c326"]
}


module "guacamole" {
  source = "../guacamole-fargate"

  hosted_zone_name   = var.hosted_zone_name
  guacadmin_password = var.guacadmin_password
  certificate_arn    = var.certificate_arn
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}
