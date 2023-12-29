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
  type    = list(string)
  default = ["subnet-05ed260b806c51c03", "subnet-07a56032c0cd3304e"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["subnet-059c12c1b12de438b", "subnet-057ca27e4dcd0c326"]
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
