module "guacamole" {
  source = "../../"

  guacadmin_password = "gu4c4m0l3" # Hardcoded for testing only
  public_subnets     = module.vpc.public_subnets
  private_subnets    = module.vpc.private_subnets
  disable_database   = true
  use_http_only      = true # Should set to false for any real deployment
  enable_nlb_logging = true
  cidr_allow_list    = ["1.2.3.4/32"]
}

output "module_outputs" {
  value = module.guacamole
}

#######################################################################################
# Supporting Resources
#######################################################################################

module "vpc" {
  version         = "5.1.2"
  source          = "terraform-aws-modules/vpc/aws"
  cidr            = "10.10.0.0/16"
  azs             = ["us-east-2a", "us-east-2b"]
  public_subnets  = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnets = ["10.10.101.0/24", "10.10.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}
