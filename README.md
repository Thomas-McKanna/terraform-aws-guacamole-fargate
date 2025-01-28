# Guacamole on Fargate Terraform Module

This Terraform module deploys an Apache Guacamole using all serverless components.
Fargate is used for Guacamole and Aurora is used for the database. The setup is
configured to scale as usage increases.

<img src="./diagram.png" width="500" alt="Architecture Diagram">

This module involves the use of a local provisioner to initialize the Guacamole databse.
In order for this local provisioner to work, ensure you have the following tools installed
on your system:

- AWS CLI
- Docker
- sed
- awk
- sha256sum (or shasum for MacOS)
- openssl

This module has was developed and tested on MacOS Sequoia.

<!-- BEGIN_TF_DOCS -->
