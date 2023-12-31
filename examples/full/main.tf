module "guacamole" {
  source = "../../"

  subdomain                      = "guac"
  hosted_zone_name               = "YOURDOMAIN.COM"
  guacadmin_password             = "gu4c4m0l3" # For testing purposes only
  public_subnets                 = module.vpc.public_subnets
  private_subnets                = module.vpc.private_subnets
  guacamole_task_security_groups = [aws_security_group.guacamole.id]
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
  cidr            = "10.20.0.0/16"
  azs             = ["us-east-2a", "us-east-2b"]
  public_subnets  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnets = ["10.20.101.0/24", "10.20.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_security_group" "guacamole" {
  name        = "guacamole-to-servers"
  description = "Allow all traffic between Guacamole and Ubuntu instances"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow all traffic from Guacamole to Ubuntu"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
}

#######################################################################################
# Guacamole Connect (comment out this code on first run, uncomment on second run)
#######################################################################################

# terraform {
#   required_providers {
#     guacamole = {
#       source  = "techBeck03/guacamole"
#       version = "1.4.1"
#     }
#   }
# }

# provider "guacamole" {
#   url                      = "https://guac.YOURDOMAIN.COM/guacamole"
#   username                 = "guacadmin"
#   password                 = "gu4c4m0l3" # For testing purposes only
#   disable_tls_verification = true
# }

# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# resource "tls_private_key" "ubuntu" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "ubuntu" {
#   public_key = tls_private_key.ubuntu.public_key_openssh
# }

# resource "aws_security_group" "ubuntu" {
#   name        = "guacamole-ubuntu-allow-internet"
#   description = "Allow all outbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_instance" "ubuntu" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t2.small"
#   key_name      = aws_key_pair.ubuntu.key_name
#   subnet_id     = module.vpc.private_subnets[0]
#   vpc_security_group_ids = [
#     aws_security_group.guacamole.id,
#     aws_security_group.ubuntu.id
#   ]

#   tags = {
#     Name = "guacamole-fargate-ubuntu"
#   }
# }

# resource "guacamole_connection_ssh" "ubuntu" {
#   depends_on        = [module.guacamole]
#   name              = "Ubuntu Test"
#   parent_identifier = "ROOT"

#   parameters {
#     hostname     = aws_instance.ubuntu.private_ip
#     username     = "ubuntu"
#     private_key  = tls_private_key.ubuntu.private_key_openssh
#     port         = 22
#     disable_copy = true
#     color_scheme = "green-black"
#     font_size    = 18
#     timezone     = "America/Chicago"
#   }
# }
