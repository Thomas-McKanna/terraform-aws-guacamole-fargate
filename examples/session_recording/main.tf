module "guacamole" {
  source = "../../"

  guacadmin_password       = "gu4c4m0l3" # Hardcoded for testing only
  public_subnets           = module.vpc.public_subnets
  private_subnets          = module.vpc.private_subnets
  use_http_only            = true # Should set to false for any real deployment
  enable_session_recording = true
  enable_execute_command   = true # For debugging
  # cidr_allow_list          = ["1.2.3.4/32"]
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
  cidr            = "10.40.0.0/16"
  azs             = ["us-east-2a", "us-east-2b"]
  public_subnets  = ["10.40.1.0/24", "10.40.2.0/24"]
  private_subnets = ["10.40.101.0/24", "10.40.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
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

# locals {
#   ubuntu_count = 3
# }

# provider "guacamole" {
#   url                      = "REPLACE ME" # Output from first run
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
#   count     = local.ubuntu_count
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "ubuntu" {
#   count      = local.ubuntu_count
#   public_key = tls_private_key.ubuntu[count.index].public_key_openssh
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
#   count         = local.ubuntu_count
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t2.small"
#   key_name      = aws_key_pair.ubuntu[count.index].key_name
#   subnet_id     = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]
#   vpc_security_group_ids = [
#     module.guacamole.allow_guacamole_sg_id,
#     aws_security_group.ubuntu.id
#   ]

#   tags = {
#     Name = "guacamole-fargate-ubuntu"
#   }
# }

# resource "guacamole_connection_ssh" "ubuntu" {
#   count             = local.ubuntu_count
#   depends_on        = [module.guacamole]
#   name              = "Ubuntu Test - ${count.index}"
#   parent_identifier = "ROOT"

#   parameters {
#     hostname     = aws_instance.ubuntu[count.index].private_ip
#     username     = "ubuntu"
#     private_key  = tls_private_key.ubuntu[count.index].private_key_openssh
#     port         = 22
#     disable_copy = true
#     color_scheme = "green-black"
#     font_size    = 18
#     timezone     = "America/Chicago"

#     recording_path             = "$${HISTORY_PATH}/$${HISTORY_UUID}"
#     recording_name             = "ubuntu-$${GUAC_USERNAME}-$${GUAC_DATE}.m4v"
#     recording_auto_create_path = true
#   }
# }
