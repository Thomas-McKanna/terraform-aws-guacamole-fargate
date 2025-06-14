module "guacamole" {
  source = "../../"

  # Example: 123456789012.dkr.ecr.us-east-2.amazonaws.com/REPO_NAME:TAG
  guac_image_uri     = "869990052760.dkr.ecr.us-east-2.amazonaws.com/custom-guacamole"
  guacadmin_password = "gu4c4m0l3" # Hardcoded for testing only
  public_subnets     = module.vpc.public_subnets
  private_subnets    = module.vpc.private_subnets
  use_http_only      = true
  cidr_allow_list    = ["0.0.0.0/0"] # Defaults to 0.0.0.0/0
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
  cidr            = "10.30.0.0/16"
  azs             = ["us-east-2a", "us-east-2b"]
  public_subnets  = ["10.30.1.0/24", "10.30.2.0/24"]
  private_subnets = ["10.30.101.0/24", "10.30.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}
