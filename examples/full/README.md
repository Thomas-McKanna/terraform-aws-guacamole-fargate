# Full Example

This example spins up Apache Guacmole (with HTTPS) and creates an example connection to
an Ubuntu server.

Requirements:

  - A hosted zone (ex. mywebsite.com)

This example uses the (techBeck03 Guacamole provider)[https://registry.terraform.io/providers/techBeck03/guacamole/latest],
which is configured with the credentials of the newly created Guacamole instance. Since
Terraform requires creating a client at the beginning of an apply, this example must
be deployed in two steps (since the Guacamole instance is not live before the first run).

Deployment steps:

  1. Ensure the hosted zone name is correct (you will need to change it from YOURZONE.COM
  to your actually domain name).
  2. Run `terraform init && terraform apply`.
  3. Uncomment the bottom section with the Guacamole provider and adjust the provider
     parameters as is necessary.
  4. Run `terraform init && terraform apply`.

You should now be able to access the Ubuntu instance through Guacamole.

NOTE: sometimes the Guacamole connections fail to be created on the first attempt. Try
running `terraform apply` again in this case.
