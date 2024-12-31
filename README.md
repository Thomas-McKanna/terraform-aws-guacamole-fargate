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

This module has was developed and tested on an Ubuntu system.

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >=5.0.0  |

## Providers

| Name                                                      | Version |
| --------------------------------------------------------- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws)          | >=5.0.0 |
| <a name="provider_null"></a> [null](#provider_null)       | n/a     |
| <a name="provider_random"></a> [random](#provider_random) | n/a     |

## Modules

| Name                                         | Source                        | Version |
| -------------------------------------------- | ----------------------------- | ------- |
| <a name="module_acm"></a> [acm](#module_acm) | terraform-aws-modules/acm/aws | 5.0.0   |

## Resources

| Name                                                                                                                                                                    | Type        |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_appautoscaling_policy.guacamole_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy)                         | resource    |
| [aws_appautoscaling_target.guacamole_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target)                         | resource    |
| [aws_cloudwatch_log_group.guacamole_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)                        | resource    |
| [aws_db_subnet_group.guacamole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group)                                            | resource    |
| [aws_ecs_cluster.fargate_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster)                                              | resource    |
| [aws_ecs_service.guacamole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)                                                    | resource    |
| [aws_ecs_task_definition.guacamole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition)                                    | resource    |
| [aws_efs_file_system.guacamole_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system)                                        | resource    |
| [aws_efs_mount_target.efs_mt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target)                                             | resource    |
| [aws_iam_policy.ecs_efs_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                                 | resource    |
| [aws_iam_policy.ecs_task_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                      | resource    |
| [aws_iam_role.ecs_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                 | resource    |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                      | resource    |
| [aws_iam_role_policy_attachment.ecs_efs_access_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)      | resource    |
| [aws_iam_role_policy_attachment.ecs_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)      | resource    |
| [aws_iam_role_policy_attachment.ecs_task_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)           | resource    |
| [aws_iam_role_policy_attachment.secret_access_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)       | resource    |
| [aws_lb.guacamole_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)                                                                   | resource    |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)                                                         | resource    |
| [aws_lb_listener.http_redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)                                                | resource    |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)                                                        | resource    |
| [aws_lb_listener_rule.redirect_root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule)                                      | resource    |
| [aws_lb_target_group.guacamole_tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)                                         | resource    |
| [aws_rds_cluster.guacamole_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster)                                                 | resource    |
| [aws_route53_record.guacamole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                                              | resource    |
| [aws_secretsmanager_secret.guacamole_db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)                 | resource    |
| [aws_secretsmanager_secret_version.guacamole_db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource    |
| [aws_security_group.alb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                 | resource    |
| [aws_security_group.ecs_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                 | resource    |
| [aws_security_group.guacamole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                              | resource    |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                 | resource    |
| [null_resource.db_init](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)                                                          | resource    |
| [random_password.guacamole_db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)                                        | resource    |
| [random_password.random_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)                                                    | resource    |
| [aws_rds_engine_version.postgresql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/rds_engine_version)                                  | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                                             | data source |
| [aws_route53_zone.zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone)                                                    | data source |
| [aws_subnet.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet)                                                     | data source |
| [aws_subnet.temp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet)                                                                | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc)                                                                      | data source |

## Inputs

| Name                                                                                                                           | Description                                                                                                                                                             | Type                | Default  | Required |
| ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | -------- | :------: |
| <a name="input_auto_pause_database"></a> [auto_pause_database](#input_auto_pause_database)                                     | Whether to automatically pause the database when not in use (this is a feature of Serverless RDS).                                                                      | `bool`              | `true`   |    no    |
| <a name="input_db_skip_final_snapshot"></a> [db_skip_final_snapshot](#input_db_skip_final_snapshot)                            | Whether to skip final snapshot when Aurora DB is destroyed.                                                                                                             | `bool`              | `true`   |    no    |
| <a name="input_enable_cloudwatch_insights"></a> [enable_cloudwatch_insights](#input_enable_cloudwatch_insights)                | Whether to enable CloudWatch Insights for Guacamole ECS cluster.                                                                                                        | `bool`              | `false`  |    no    |
| <a name="input_enable_execute_command"></a> [enable_execute_command](#input_enable_execute_command)                            | If true, will enable the use of execute_command on the ECS tasks (useful for debugging).                                                                                | `bool`              | `false`  |    no    |
| <a name="input_enable_session_recording"></a> [enable_session_recording](#input_enable_session_recording)                      | If true, sessions will be recorded and stored in an AWS Elastic File System (EFS) instance.                                                                             | `bool`              | `false`  |    no    |
| <a name="input_guac_image_uri"></a> [guac_image_uri](#input_guac_image_uri)                                                    | ARN of custom Guacamole image to use. If not provided, will use latest version of `guacamole/guacamole`.                                                                | `string`            | `""`     |    no    |
| <a name="input_guacadmin_password"></a> [guacadmin_password](#input_guacadmin_password)                                        | Password for guacadmin user (a new random salt will be generated).                                                                                                      | `string`            | n/a      |   yes    |
| <a name="input_guacamole_task_environment_vars"></a> [guacamole_task_environment_vars](#input_guacamole_task_environment_vars) | Environment variables to pass to Guacamole task (database environment variables are automatically passed). Should be list of dictionaries with keys `name` and `value`. | `list(map(string))` | `[]`     |    no    |
| <a name="input_guacamole_task_security_groups"></a> [guacamole_task_security_groups](#input_guacamole_task_security_groups)    | IDs of security groups to attach to Guacamole ECS task.                                                                                                                 | `list(string)`      | `[]`     |    no    |
| <a name="input_hosted_zone_name"></a> [hosted_zone_name](#input_hosted_zone_name)                                              | If provided, will create DNS record in this hosted zone for load balancer. Not used if `use_http_only` is true.                                                         | `string`            | `""`     |    no    |
| <a name="input_log_level"></a> [log_level](#input_log_level)                                                                   | Log level for Guacamole.                                                                                                                                                | `string`            | `"info"` |    no    |
| <a name="input_maximum_guacamole_task_count"></a> [maximum_guacamole_task_count](#input_maximum_guacamole_task_count)          | Maximum number of Guacamole tasks to run at once (for autoscaling). Minimum number of tasks is always 1.                                                                | `number`            | `10`     |    no    |
| <a name="input_private_subnets"></a> [private_subnets](#input_private_subnets)                                                 | Subnets to place Fargate and Aurora in.                                                                                                                                 | `list(string)`      | n/a      |   yes    |
| <a name="input_public_subnets"></a> [public_subnets](#input_public_subnets)                                                    | Subnets to place load balancer in.                                                                                                                                      | `list(string)`      | n/a      |   yes    |
| <a name="input_seconds_until_auto_pause"></a> [seconds_until_auto_pause](#input_seconds_until_auto_pause)                      | Number of seconds of inactivity before database is automatically paused.                                                                                                | `number`            | `300`    |    no    |
| <a name="input_subdomain"></a> [subdomain](#input_subdomain)                                                                   | Subdomain within hosted zone to create DNS record for load balancer. Not used if `use_http_only` is true. If not provided, Guacamole URL will be for base hosted zone.  | `string`            | `""`     |    no    |
| <a name="input_use_http_only"></a> [use_http_only](#input_use_http_only)                                                       | Whether to use HTTP only for load balancer (should just be for evaluating the module and automated tested).                                                             | `bool`              | `false`  |    no    |

## Outputs

| Name                                                                             | Description                                                             |
| -------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| <a name="output_guacamole_sg_id"></a> [guacamole_sg_id](#output_guacamole_sg_id) | ID of security group which allows communication with Guacamole instance |
| <a name="output_guacamole_url"></a> [guacamole_url](#output_guacamole_url)       | URL of Guacamole instance                                               |

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >=5.0.0  |

## Providers

| Name                                                         | Version |
| ------------------------------------------------------------ | ------- |
| <a name="provider_archive"></a> [archive](#provider_archive) | n/a     |
| <a name="provider_aws"></a> [aws](#provider_aws)             | >=5.0.0 |
| <a name="provider_null"></a> [null](#provider_null)          | n/a     |
| <a name="provider_random"></a> [random](#provider_random)    | n/a     |
| <a name="provider_time"></a> [time](#provider_time)          | n/a     |

## Modules

| Name                                         | Source                        | Version |
| -------------------------------------------- | ----------------------------- | ------- |
| <a name="module_acm"></a> [acm](#module_acm) | terraform-aws-modules/acm/aws | 5.0.0   |

## Resources

| Name                                                                                                                                                                    | Type        |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_appautoscaling_policy.guacamole_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy)                         | resource    |
| [aws_appautoscaling_target.guacamole_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target)                         | resource    |
| [aws_cloudwatch_log_group.guacamole_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)                        | resource    |
| [aws_db_subnet_group.guacamole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group)                                            | resource    |
| [aws_ecs_cluster.fargate_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster)                                              | resource    |
| [aws_ecs_service.guacamole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)                                                    | resource    |
| [aws_ecs_task_definition.guacamole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition)                                    | resource    |
| [aws_efs_access_point.guacamole_efs_access_point](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point)                         | resource    |
| [aws_efs_file_system.guacamole_efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system)                                        | resource    |
| [aws_efs_file_system_policy.guacamole_efs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system_policy)                   | resource    |
| [aws_efs_mount_target.efs_mt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target)                                             | resource    |
| [aws_iam_policy.ecs_task_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                      | resource    |
| [aws_iam_role.ecs_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                 | resource    |
| [aws_iam_role.ecs_task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                      | resource    |
| [aws_iam_role.lambda_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                        | resource    |
| [aws_iam_role_policy_attachment.ecs_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)      | resource    |
| [aws_iam_role_policy_attachment.ecs_task_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)           | resource    |
| [aws_iam_role_policy_attachment.lambda_exec_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)             | resource    |
| [aws_iam_role_policy_attachment.secret_access_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)       | resource    |
| [aws_lambda_function.cors_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)                                         | resource    |
| [aws_lambda_permission.allow_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission)                                        | resource    |
| [aws_lb.guacamole_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)                                                                   | resource    |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)                                                         | resource    |
| [aws_lb_listener.http_redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)                                                | resource    |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)                                                        | resource    |
| [aws_lb_listener_rule.cors_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule)                                          | resource    |
| [aws_lb_listener_rule.redirect_root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule)                                      | resource    |
| [aws_lb_target_group.guacamole_tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)                                         | resource    |
| [aws_lb_target_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)                                               | resource    |
| [aws_lb_target_group_attachment.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment)                         | resource    |
| [aws_rds_cluster.guacamole_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster)                                                 | resource    |
| [aws_route53_record.guacamole](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)                                              | resource    |
| [aws_s3_bucket.alb_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)                                                      | resource    |
| [aws_s3_bucket_policy.alb_logging_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy)                                 | resource    |
| [aws_secretsmanager_secret.guacamole_db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)                 | resource    |
| [aws_secretsmanager_secret_version.guacamole_db_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource    |
| [aws_security_group.alb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                 | resource    |
| [aws_security_group.allow_guacamole_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                             | resource    |
| [aws_security_group.ecs_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                 | resource    |
| [aws_security_group.guacamole_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                       | resource    |
| [aws_security_group.rds_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                 | resource    |
| [aws_security_group.recordings_efs_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                  | resource    |
| [aws_wafv2_ip_set.allowlist](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set)                                                  | resource    |
| [aws_wafv2_web_acl.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl)                                                  | resource    |
| [aws_wafv2_web_acl_association.load_balancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association)                    | resource    |
| [null_resource.db_init](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource)                                                          | resource    |
| [random_password.guacamole_db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)                                        | resource    |
| [random_password.random_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)                                                    | resource    |
| [time_sleep.wait_for_db](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep)                                                            | resource    |
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file)                                                      | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                                           | data source |
| [aws_rds_engine_version.postgresql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/rds_engine_version)                                  | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                                             | data source |
| [aws_route53_zone.zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone)                                                    | data source |
| [aws_subnet.private_subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet)                                                     | data source |
| [aws_subnet.temp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet)                                                                | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc)                                                                      | data source |

## Inputs

| Name                                                                                                                           | Description                                                                                                                                                             | Type                | Default                           | Required |
| ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | --------------------------------- | :------: |
| <a name="input_auto_pause_database"></a> [auto_pause_database](#input_auto_pause_database)                                     | Whether to automatically pause the database when not in use (this is a feature of Serverless RDS).                                                                      | `bool`              | `false`                           |    no    |
| <a name="input_brute_force_allow_list"></a> [brute_force_allow_list](#input_brute_force_allow_list)                            | List of CIDRs to always allow through WAF. If a single IP, write like `1.2.3.4/32`.                                                                                     | `list(string)`      | `[]`                              |    no    |
| <a name="input_cidr_allow_list"></a> [cidr_allow_list](#input_cidr_allow_list)                                                 | List of IP address ranges (CIDRs) to allow access to Guacamole. All other IP addresses will be blocked. If a single IP, write like `1.1.1.1/32`.                        | `list(string)`      | <pre>[<br> "0.0.0.0/0"<br>]</pre> |    no    |
| <a name="input_cors_allowed_origin"></a> [cors_allowed_origin](#input_cors_allowed_origin)                                     | Origin to allow for CORS requests to `/guacamole/api/tokens`. If not provided, will not set CORS header.                                                                | `string`            | `""`                              |    no    |
| <a name="input_db_enable_deletion_protection"></a> [db_enable_deletion_protection](#input_db_enable_deletion_protection)       | Whether to enable deletion protection for Aurora DB.                                                                                                                    | `bool`              | `false`                           |    no    |
| <a name="input_db_skip_final_snapshot"></a> [db_skip_final_snapshot](#input_db_skip_final_snapshot)                            | Whether to skip final snapshot when Aurora DB is destroyed.                                                                                                             | `bool`              | `true`                            |    no    |
| <a name="input_disable_database"></a> [disable_database](#input_disable_database)                                              | If true, will not create an Aurora database for Guacamole. Can be cost-efficient if not using JDBC auth plugin.                                                         | `bool`              | `false`                           |    no    |
| <a name="input_efs_tags"></a> [efs_tags](#input_efs_tags)                                                                      | Tags to apply to EFS instance.                                                                                                                                          | `map(string)`       | `{}`                              |    no    |
| <a name="input_enable_alb_logging"></a> [enable_alb_logging](#input_enable_alb_logging)                                        | Whether to enable logging for the ALB.                                                                                                                                  | `bool`              | `false`                           |    no    |
| <a name="input_enable_brute_force_protection"></a> [enable_brute_force_protection](#input_enable_brute_force_protection)       | If enabled, will create Web Application Firewall (WAF) rules to block brute force attacks.                                                                              | `bool`              | `true`                            |    no    |
| <a name="input_enable_cloudwatch_insights"></a> [enable_cloudwatch_insights](#input_enable_cloudwatch_insights)                | Whether to enable CloudWatch Insights for Guacamole ECS cluster.                                                                                                        | `bool`              | `false`                           |    no    |
| <a name="input_enable_execute_command"></a> [enable_execute_command](#input_enable_execute_command)                            | If true, will enable the use of execute_command on the ECS tasks (useful for debugging).                                                                                | `bool`              | `false`                           |    no    |
| <a name="input_enable_session_recording"></a> [enable_session_recording](#input_enable_session_recording)                      | If true, sessions will be recorded and stored in an AWS Elastic File System (EFS) instance.                                                                             | `bool`              | `false`                           |    no    |
| <a name="input_guac_image_uri"></a> [guac_image_uri](#input_guac_image_uri)                                                    | ARN of custom Guacamole image to use. If not provided, will use latest version of `guacamole/guacamole`.                                                                | `string`            | `""`                              |    no    |
| <a name="input_guacadmin_password"></a> [guacadmin_password](#input_guacadmin_password)                                        | Password for guacadmin user (a new random salt will be generated).                                                                                                      | `string`            | `"guacadmin"`                     |    no    |
| <a name="input_guacamole_task_cpu"></a> [guacamole_task_cpu](#input_guacamole_task_cpu)                                        | Number of vCPU to allocate to Guacamole task. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html.                               | `number`            | `1024`                            |    no    |
| <a name="input_guacamole_task_environment_vars"></a> [guacamole_task_environment_vars](#input_guacamole_task_environment_vars) | Environment variables to pass to Guacamole task (database environment variables are automatically passed). Should be list of dictionaries with keys `name` and `value`. | `list(map(string))` | `[]`                              |    no    |
| <a name="input_guacamole_task_memory"></a> [guacamole_task_memory](#input_guacamole_task_memory)                               | Amount of memory in MiB to allocate to Guacamole task. See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html.                      | `number`            | `2048`                            |    no    |
| <a name="input_guacamole_task_security_groups"></a> [guacamole_task_security_groups](#input_guacamole_task_security_groups)    | IDs of security groups to attach to Guacamole ECS task.                                                                                                                 | `list(string)`      | `[]`                              |    no    |
| <a name="input_hosted_zone_name"></a> [hosted_zone_name](#input_hosted_zone_name)                                              | If provided, will create DNS record in this hosted zone for load balancer. Not used if `use_http_only` is true.                                                         | `string`            | `""`                              |    no    |
| <a name="input_log_level"></a> [log_level](#input_log_level)                                                                   | Log level for Guacamole.                                                                                                                                                | `string`            | `"info"`                          |    no    |
| <a name="input_maximum_guacamole_task_count"></a> [maximum_guacamole_task_count](#input_maximum_guacamole_task_count)          | Maximum number of Guacamole tasks to run at once (for autoscaling). Minimum number of tasks is always 1.                                                                | `number`            | `10`                              |    no    |
| <a name="input_private_subnets"></a> [private_subnets](#input_private_subnets)                                                 | Subnets to place Fargate and Aurora in.                                                                                                                                 | `list(string)`      | n/a                               |   yes    |
| <a name="input_public_subnets"></a> [public_subnets](#input_public_subnets)                                                    | Subnets to place load balancer in.                                                                                                                                      | `list(string)`      | n/a                               |   yes    |
| <a name="input_seconds_until_auto_pause"></a> [seconds_until_auto_pause](#input_seconds_until_auto_pause)                      | Number of seconds of inactivity before database is automatically paused.                                                                                                | `number`            | `300`                             |    no    |
| <a name="input_subdomain"></a> [subdomain](#input_subdomain)                                                                   | Subdomain within hosted zone to create DNS record for load balancer. Not used if `use_http_only` is true. If not provided, Guacamole URL will be for base hosted zone.  | `string`            | `""`                              |    no    |
| <a name="input_use_http_only"></a> [use_http_only](#input_use_http_only)                                                       | Whether to use HTTP only for load balancer (should just be for evaluating the module and automated tested).                                                             | `bool`              | `false`                           |    no    |

## Outputs

| Name                                                                                                                                                     | Description                                                                                                                      |
| -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| <a name="output_alb_logging_bucket"></a> [alb_logging_bucket](#output_alb_logging_bucket)                                                                | Name of S3 bucket which stores ALB logs (requires setting enable_alb_logging to true)                                            |
| <a name="output_allow_guacamole_sg_id"></a> [allow_guacamole_sg_id](#output_allow_guacamole_sg_id)                                                       | ID of security group which allows Guacamole to connect to remote resources. Apply this to remote resources.                      |
| <a name="output_guacamole_url"></a> [guacamole_url](#output_guacamole_url)                                                                               | URL of Guacamole instance                                                                                                        |
| <a name="output_recordings_efs_access_point_id"></a> [recordings_efs_access_point_id](#output_recordings_efs_access_point_id)                            | ID of EFS access point which can be used to access Guacamole recordings (requires setting enable_recording to true)              |
| <a name="output_recordings_efs_access_security_group_id"></a> [recordings_efs_access_security_group_id](#output_recordings_efs_access_security_group_id) | ID of security group which allows Guacamole to access EFS file system for recordings (requires setting enable_recording to true) |
| <a name="output_recordings_efs_id"></a> [recordings_efs_id](#output_recordings_efs_id)                                                                   | ID of EFS file system which stores Guacamole recordings (requires setting enable_recording to true)                              |

<!-- END_TF_DOCS -->
