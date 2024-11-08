terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0.0"
    }
  }
}

locals {
  guac_container_name    = "guacamole"
  guacamole_db_name      = "guacamoledb"
  guacamole_db_username  = "pgadmin"
  session_recording_path = "/var/lib/guacamole/recordings" # This is the Guac default
  log_group              = "/ecs/guacamole-${random_password.random_id.result}"
  fqdn                   = var.hosted_zone_name != "" ? (var.subdomain != "" ? "${var.subdomain}.${var.hosted_zone_name}" : "${var.hosted_zone_name}") : aws_lb.guacamole_lb.dns_name
  guac_url               = var.hosted_zone_name != "" ? "https://${local.fqdn}/guacamole/" : "http://${aws_lb.guacamole_lb.dns_name}/guacamole/"
  guac_image             = var.guac_image_uri != "" ? var.guac_image_uri : "guacamole/guacamole"
  ecr_repository_arn     = var.guac_image_uri != "" ? format("arn:aws:ecr:%s:%s:repository/%s", element(split(".", var.guac_image_uri), 3), element(split(".", var.guac_image_uri), 0), element(split("/", split(":", var.guac_image_uri)[0]), 1)) : ""
  create_cors_lambda     = var.cors_allowed_origin != ""

  session_recording_env = var.enable_session_recording ? [
    {
      name  = "RECORDING_SEARCH_PATH"
      value = local.session_recording_path
    }
  ] : []

  mount_points = var.enable_session_recording ? [
    {
      sourceVolume  = "efs_volume",
      containerPath = local.session_recording_path,
      readOnly      = false
    }
  ] : []

  depends_on = var.enable_session_recording ? [
    {
      containerName = "init-efs",
      condition     = "SUCCESS"
    }
  ] : []

  init_container_def = var.enable_session_recording ? [
    {
      name        = "init-efs"
      image       = "alpine:latest"
      essential   = false
      command     = ["/bin/sh", "-c", "chown -R 1000:1001 ${local.session_recording_path} && chmod 2750 ${local.session_recording_path}"]
      mountPoints = local.mount_points
    }
  ] : []

  container_defs = [
    {
      name      = local.guac_container_name
      image     = local.guac_image
      essential = true
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080
        }
      ],
      environment = concat(
        local.session_recording_env,
        var.guacamole_task_environment_vars,
        [
          {
            name  = "POSTGRESQL_HOSTNAME",
            value = aws_rds_cluster.guacamole_db.endpoint
          },
          {
            name  = "POSTGRESQL_DATABASE",
            value = local.guacamole_db_name
          },
          {
            name  = "GUACD_HOSTNAME",
            value = "localhost"
          },
          {
            name  = "GUACD_PORT",
            value = "4822"
          },
          {
            name  = "GUACD_LOG_LEVEL",
            value = var.log_level
          },
        ]
      ),
      secrets = [
        {
          name      = "POSTGRESQL_USER",
          valueFrom = "${aws_secretsmanager_secret.guacamole_db_credentials.arn}:username::"
        },
        {
          name      = "POSTGRESQL_PASSWORD",
          valueFrom = "${aws_secretsmanager_secret.guacamole_db_credentials.arn}:password::"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = local.log_group,
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "guacamole"
        }
      },
      mountPoints = local.mount_points,
      dependsOn   = local.depends_on
    },
    {
      name      = "guacd"
      image     = "guacamole/guacd"
      essential = true
      portMappings = [
        {
          containerPort = 4822,
          hostPort      = 4822
        }
      ],
      environment = concat(
        local.session_recording_env,
        var.guacamole_task_environment_vars,
        [
          {
            name  = "GUACD_LOG_LEVEL",
            value = var.log_level
          }
        ]
      ),
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = local.log_group,
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "guacd"
        }
      },
      mountPoints = local.mount_points,
      dependsOn   = local.depends_on
    }
  ]
}

data "aws_subnet" "temp" {
  id = var.private_subnets[0]
}

data "aws_vpc" "this" {
  id = data.aws_subnet.temp.vpc_id
}

data "aws_subnet" "private_subnets" {
  count = length(var.private_subnets)
  id    = var.private_subnets[count.index]
}

resource "random_password" "random_id" {
  length  = 8
  special = false
  numeric = false
  upper   = false
}

resource "aws_db_subnet_group" "guacamole" {
  name       = "guacamole-db-subnet-group-${random_password.random_id.result}"
  subnet_ids = var.private_subnets
}

resource "random_password" "guacamole_db_password" {
  length           = 16
  special          = true
  override_special = "$&!%"
}

data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = "14.5"
}

resource "aws_security_group" "rds_sg" {
  name        = "guacamole-db-sg-${random_password.random_id.result}"
  description = "Security group for RDS"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = data.aws_subnet.private_subnets.*.cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_cluster" "guacamole_db" {
  cluster_identifier     = "guacamole-db-${random_password.random_id.result}"
  engine                 = "aurora-postgresql"
  db_subnet_group_name   = aws_db_subnet_group.guacamole.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  master_username        = local.guacamole_db_username
  master_password        = random_password.guacamole_db_password.result
  skip_final_snapshot    = var.db_skip_final_snapshot
  deletion_protection    = var.db_enable_deletion_protection

  database_name = local.guacamole_db_name

  engine_mode          = "serverless"
  enable_http_endpoint = true
  scaling_configuration {
    auto_pause               = var.auto_pause_database
    min_capacity             = 2
    max_capacity             = 32
    seconds_until_auto_pause = var.seconds_until_auto_pause
  }
}

# Sleep 2 minutes
resource "time_sleep" "wait_for_db" {
  depends_on      = [aws_rds_cluster.guacamole_db]
  create_duration = "2m"
}

resource "null_resource" "db_init" {
  depends_on = [time_sleep.wait_for_db]

  provisioner "local-exec" {
    command = <<EOT
      export DB_ARN="${aws_rds_cluster.guacamole_db.arn}"
      export DB_SECRET_ARN="${aws_secretsmanager_secret.guacamole_db_credentials.arn}"
      export DB_NAME="${local.guacamole_db_name}"
      export GUACADMIN_PASSWORD="${var.guacadmin_password}"
      ${path.module}/init_db.sh
    EOT
  }
}

resource "aws_secretsmanager_secret" "guacamole_db_credentials" {
  name                    = "guacamole-db-credentials-${random_password.random_id.result}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "guacamole_db_credentials" {
  secret_id = aws_secretsmanager_secret.guacamole_db_credentials.id
  secret_string = jsonencode({
    username = local.guacamole_db_username
    password = random_password.guacamole_db_password.result
  })
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role_${random_password.random_id.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "guacamole_ecs_execution_policy-${random_password.random_id.result}"
  description = "Policy to access secrets in Secrets Manager and optionally custom Guacamole image in ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat([
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.guacamole_db_credentials.arn
      }
      ], var.guac_image_uri != "" ? [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        Resource = local.ecr_repository_arn
      }
    ] : [])
  })
}

resource "aws_iam_role_policy_attachment" "secret_access_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}


data "aws_region" "current" {}

resource "aws_security_group" "alb_sg" {
  name        = "guacamole-alb-sg-${random_password.random_id.result}"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_allow_list
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cidr_allow_list
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role_${random_password.random_id.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ecs_task_definition" "guacamole" {
  family                   = "guacamole-task-${random_password.random_id.result}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = var.guacamole_task_cpu
  memory                   = var.guacamole_task_memory

  dynamic "volume" {
    for_each = var.enable_session_recording ? [1] : []
    content {
      name = "efs_volume"

      efs_volume_configuration {
        file_system_id     = aws_efs_file_system.guacamole_efs[0].id
        root_directory     = "/"
        transit_encryption = "ENABLED"
        authorization_config {
          iam = "ENABLED"
        }
      }
    }
  }

  container_definitions = jsonencode(concat(local.init_container_def, local.container_defs))
}

resource "aws_lb" "guacamole_lb" {
  name                       = "guacamole-lb-${random_password.random_id.result}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = var.public_subnets
  drop_invalid_header_fields = true

  enable_deletion_protection = false

  dynamic "access_logs" {
    for_each = var.enable_alb_logging ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logging[0].bucket
      prefix  = "alb-logs"
      enabled = true
    }
  }
}

resource "aws_s3_bucket" "alb_logging" {
  count = var.enable_alb_logging ? 1 : 0

  bucket        = "guacamole-alb-logging-${random_password.random_id.result}"
  force_destroy = true
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "alb_logging_policy" {
  count  = var.enable_alb_logging ? 1 : 0
  bucket = aws_s3_bucket.alb_logging[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::033677994240:root"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.alb_logging[0].bucket}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}



data "aws_route53_zone" "zone" {
  count = var.use_http_only ? 0 : 1

  name = var.hosted_zone_name
}

resource "aws_route53_record" "guacamole" {
  count = var.use_http_only ? 0 : 1

  zone_id = data.aws_route53_zone.zone[0].zone_id
  name    = local.fqdn
  type    = "A"
  alias {
    name                   = aws_lb.guacamole_lb.dns_name
    zone_id                = aws_lb.guacamole_lb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_lb_listener" "http" {
  count = var.use_http_only ? 1 : 0

  load_balancer_arn = aws_lb.guacamole_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.guacamole_tg.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  count = var.use_http_only ? 0 : 1

  load_balancer_arn = aws_lb.guacamole_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

module "acm" {
  count = var.use_http_only ? 0 : 1

  source  = "terraform-aws-modules/acm/aws"
  version = "5.0.0"

  domain_name = var.hosted_zone_name
  zone_id     = data.aws_route53_zone.zone[0].zone_id

  validation_method = "DNS"

  wait_for_validation = true

  subject_alternative_names = [local.fqdn]
}

resource "aws_lb_listener" "https" {
  count = var.use_http_only ? 0 : 1

  load_balancer_arn = aws_lb.guacamole_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = module.acm[0].acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.guacamole_tg.arn
  }
}

# Add a new listener rule for CORS handling
resource "aws_lb_listener_rule" "cors_rule" {
  count        = local.create_cors_lambda ? 1 : 0
  listener_arn = var.use_http_only ? aws_lb_listener.http[0].arn : aws_lb_listener.https[0].arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda[0].arn
  }

  condition {
    http_request_method {
      values = ["OPTIONS"]
    }
  }

  condition {
    path_pattern {
      values = ["/guacamole/api/tokens"]
    }
  }
}

resource "aws_lb_listener_rule" "redirect_root" {
  count = var.use_http_only ? 0 : 1

  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
      path        = "/guacamole"
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_target_group" "guacamole_tg" {
  name        = "guacamole-tg-${random_password.random_id.result}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.this.id
  target_type = "ip"

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400 # 86400 seconds = 1 day.
  }

  health_check {
    path     = "/guacamole/"
    port     = 8080
    protocol = "HTTP"
  }
}

resource "aws_cloudwatch_log_group" "guacamole_log_group" {
  name = local.log_group
}

resource "aws_ecs_cluster" "fargate_cluster" {
  name = "guacamole-cluster-${random_password.random_id.result}"

  setting {
    name  = "containerInsights"
    value = var.enable_cloudwatch_insights ? "enabled" : "disabled"
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "guacamole-ecs-sg-${random_password.random_id.result}"
  description = "Security group for ECS Tasks"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Needed for fetching secrets from Secrets Manager and for accessing RDS
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "recordings_efs_access" {
  count       = var.enable_session_recording ? 1 : 0
  name        = "guacamole-efs-sg-${random_password.random_id.result}"
  description = "Security group for EFS access"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
}

resource "aws_security_group" "guacamole_server" {
  name        = "guacamole-server-sg-${random_password.random_id.result}"
  description = "Attached to Guacamole servers (used by allow-guacamole-sg)"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_security_group" "allow_guacamole_connection" {
  name        = "allow-guacamole-sg-${random_password.random_id.result}"
  description = "Allow all traffic from Guacamole"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    description = "Allow all traffic between security group members"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [
      aws_security_group.guacamole_server.id
    ]
  }
}

resource "aws_ecs_service" "guacamole" {
  depends_on             = [null_resource.db_init]
  name                   = "guacamole-service-${random_password.random_id.result}"
  cluster                = aws_ecs_cluster.fargate_cluster.id
  task_definition        = aws_ecs_task_definition.guacamole.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = var.enable_execute_command

  network_configuration {
    # Choose just first subnet so that Guac operates in a single AZ
    subnets          = [var.private_subnets[0]]
    assign_public_ip = false

    security_groups = concat([
      aws_security_group.ecs_sg.id,
      aws_security_group.guacamole_server.id],
      var.guacamole_task_security_groups,
    var.enable_session_recording ? [aws_security_group.recordings_efs_access[0].id] : [])
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.guacamole_tg.arn
    container_name   = local.guac_container_name
    container_port   = 8080
  }
}

resource "aws_appautoscaling_target" "guacamole_target" {
  max_capacity       = var.maximum_guacamole_task_count
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.fargate_cluster.name}/${aws_ecs_service.guacamole.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "guacamole_policy" {
  name               = "guacamole_autoscaling_policy_${random_password.random_id.result}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.guacamole_target.resource_id
  scalable_dimension = aws_appautoscaling_target.guacamole_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.guacamole_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 50.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_efs_file_system" "guacamole_efs" {
  count          = var.enable_session_recording ? 1 : 0
  creation_token = "guacamole-efs-${random_password.random_id.result}"
  encrypted      = true

  tags = merge(
    {
      Name = "guacamole-efs-${random_password.random_id.result}"
    },
    var.efs_tags
  )
}

resource "aws_efs_file_system_policy" "guacamole_efs_policy" {
  count          = var.enable_session_recording ? 1 : 0
  file_system_id = aws_efs_file_system.guacamole_efs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccessFromGuacamoleECS"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        }
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
        ]
        Resource = aws_efs_file_system.guacamole_efs[0].arn
      }
    ]
  })
}

resource "aws_efs_mount_target" "efs_mt" {
  count           = var.enable_session_recording ? length(var.private_subnets) : 0
  file_system_id  = aws_efs_file_system.guacamole_efs[0].id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.recordings_efs_access[0].id]
}

resource "aws_wafv2_ip_set" "allowlist" {
  count = var.enable_brute_force_protection && var.brute_force_allow_list != [] ? 1 : 0

  name               = "guac-ip-allowlist-${random_password.random_id.result}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.brute_force_allow_list
}

resource "aws_wafv2_web_acl" "example" {
  count = var.enable_brute_force_protection ? 1 : 0

  name        = "guac-acl-${random_password.random_id.result}"
  scope       = "REGIONAL"
  description = "ACL for brute-force login attempts mitigation"

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = length(var.brute_force_allow_list) > 0 ? [1] : []
    content {
      name     = "IPAllowlist"
      priority = 0

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowlist[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "GuacIPAllowlist-${random_password.random_id.result}"
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "RateLimit"
    priority = 1

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GuacRateLimit-${random_password.random_id.result}"
      sampled_requests_enabled   = true
    }

    statement {
      rate_based_statement {
        limit              = 100 # Set the rate limit to 100 requests per 5 minutes
        aggregate_key_type = "IP"
        scope_down_statement {
          byte_match_statement {
            field_to_match {
              uri_path {}
            }
            positional_constraint = "ENDS_WITH"
            search_string         = "/api/tokens"
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "GuacAcl-${random_password.random_id.result}"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "load_balancer" {
  count = var.enable_brute_force_protection ? 1 : 0

  resource_arn = aws_lb.guacamole_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.example[0].arn
}

resource "aws_lambda_function" "cors_handler" {
  count         = local.create_cors_lambda ? 1 : 0
  function_name = "guacamole-cors-handler-${random_password.random_id.result}"
  role          = aws_iam_role.lambda_exec[0].arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  filename      = data.archive_file.lambda_zip[0].output_path

  environment {
    variables = {
      ALLOWED_ORIGIN = var.cors_allowed_origin
    }
  }

  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256
}

data "archive_file" "lambda_zip" {
  count       = local.create_cors_lambda ? 1 : 0
  type        = "zip"
  output_path = "${path.module}/cors_lambda_function_${random_password.random_id.result}.zip"

  source {
    content  = <<EOF
import os

def lambda_handler(event, context):
    allowed_origin = os.environ['ALLOWED_ORIGIN']
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': allowed_origin,
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        'body': ''
    }
EOF
    filename = "lambda_function.py"
  }
}

resource "aws_iam_role" "lambda_exec" {
  count = local.create_cors_lambda ? 1 : 0
  name  = "guacamole-lambda-exec-${random_password.random_id.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  count      = local.create_cors_lambda ? 1 : 0
  role       = aws_iam_role.lambda_exec[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lb_target_group" "lambda" {
  count       = local.create_cors_lambda ? 1 : 0
  name        = "guacamole-lambda-tg-${random_password.random_id.result}"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "lambda" {
  count            = local.create_cors_lambda ? 1 : 0
  target_group_arn = aws_lb_target_group.lambda[0].arn
  target_id        = aws_lambda_function.cors_handler[0].arn
}

resource "aws_lambda_permission" "allow_alb" {
  count         = local.create_cors_lambda ? 1 : 0
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cors_handler[0].function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda[0].arn
}
