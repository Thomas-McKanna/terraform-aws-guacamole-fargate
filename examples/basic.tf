variable "hosted_zone_name" {
  type = string
}

variable "guacadmin_password" {
  type      = string
  sensitive = true
}

variable "certificate_arn" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}


module "guacamole" {
  source = "../"

  hosted_zone_name   = var.hosted_zone_name
  guacadmin_password = var.guacadmin_password
  certificate_arn    = var.certificate_arn
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}


output "module_outputs" {
  value = module.guacamole
}
