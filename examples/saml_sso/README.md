# Guacamole with SAML SSO

SAML SSO allows for logging in with an external identity provider.

See https://guacamole.apache.org/doc/gug/saml-auth.html# for full documentation.

This approach uses a custom Docker image that has the SAML extension installed and
configured.

Steps to deploy example:

1. Configure SAML identity provider. For entity ID, use the expected Guacamole URL.
   For the callback URL, use that same Guacamole URL. Note down metadata URL for the
   next step.
2. Alter the Dockerfile to set the entity ID, callback URL, and metadata URL. You will
   also need to alter the `saml-group-attribute` if you are using an IdP other than
   Entra ID. You should configure the IdP to include this attribute in the SAM response,
   and it should contain the group names that the user is a member of.
3. Create an ECR repo in AWS.
4. Run `./ecr_push repo_name tag_name`, where you specify the `repo_name` and `tag_name`
   (can be anything). This script requires your terminal to be authenticated to AWS.
5. Go into your ECR repo and copy the newly created image URI.
6. Paste the URI in `main.tf`.
7. Run `terraform init && terraform apply`.
8. Now uncomment the Guacamole and EC2 resources in `main.tf`. Then run
   `terraform init -upgrade && terraform apply`.
9. Navigate to the output URL and see the customized Guacamole login page. You should
   see "Login with SAML" in the bottom left corner. For now, log in as the admin in the
   original Guacamole login interface (password in Terraform configuration). Add a
   group with the same name as the group of relevant users in the IdP and add the
   test Ubuntu connection to the group. This process is how you map groups to
   connections.
10. Log out and try to log in as an SSO user. You should be redirected to the IdP login
    page. After logging in, you should be redirected back to Guacamole and logged in
    and have access to the Ubuntu connection.
