# Custom Guacamole Image

If you would like to customize the docker image to enable certain extensions, you can
do so by uploading a custom image to AWS ECR and using it in place of the default
`guacamole/guacamole` image.

This example builds out a Guacamole docker image with customized branding
(see [branding extension docs](https://github.com/Zer0CoolX/guacamole-customize-loginscreen-extension)).

Steps to deploy example:

1. Create an ECR repo in AWS.
2. Run `./ecr_push repo_name tag_name`, where you specify the `repo_name` and `tag_name`
   (can be anything). This script requires your terminal to be authenticated to AWS.
3. Go into your ECR repo and copy the newly created image URI.
4. Paste the URI in `main.tf`.
5. Run `terraform init && terraform apply`.
6. Navigate to the output URL and see the customized Guacamole login page.
