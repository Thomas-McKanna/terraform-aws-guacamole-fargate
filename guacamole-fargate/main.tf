# TODO: randomize names of resources; tagging

locals {
  guac_container_name   = "guacamole"
  guacamole_db_name     = "guacamoledb"
  guacamole_db_username = "pgadmin"
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

resource "aws_db_subnet_group" "guacamole" {
  name       = "guacamole"
  subnet_ids = var.private_subnets
}

resource "random_password" "guacamole_db_password" {
  length           = 16
  special          = true
  override_special = "/_%@\" "
}

data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = "14.5"
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
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
  cluster_identifier     = "guacamole-db"
  engine                 = "aurora-postgresql"
  db_subnet_group_name   = aws_db_subnet_group.guacamole.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  master_username        = local.guacamole_db_username
  master_password        = random_password.guacamole_db_password.result
  skip_final_snapshot    = var.db_skip_final_snapshot

  database_name = local.guacamole_db_name

  engine_mode          = "serverless"
  enable_http_endpoint = true
  scaling_configuration {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 32
    seconds_until_auto_pause = 300
  }
}

resource "null_resource" "db_init" {
  depends_on = [aws_rds_cluster.guacamole_db]

  provisioner "local-exec" {
    command = <<EOT
      ORIG_HASH="CA458A7D494E3BE824F5E1E175A1556C0F8EEF2C2D7DF3633BEC4A29C4411960" # guacadmin
      # Still using the original salt
      NEW_HASH=$(echo -n "${var.guacadmin_password}FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264" | sha256sum | awk '{ print toupper($1) }')
      docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgresql > /tmp/initdb.sql
      sed -i 's/'"$ORIG_HASH"'/'"$NEW_HASH"'/g' /tmp/initdb.sql
      aws rds-data execute-statement \
          --resource-arn "${aws_rds_cluster.guacamole_db.arn}" \
          --secret-arn "${aws_secretsmanager_secret.guacamole_db_credentials.arn}" \
          --database "${local.guacamole_db_name}" \
          --sql "file:///tmp/initdb.sql"
    EOT
  }
}

resource "aws_secretsmanager_secret" "guacamole_db_credentials" {
  name                    = "guacamole-db-credentials"
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
  name = "ecs_execution_role"

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

resource "aws_iam_policy" "secret_access" {
  name        = "SecretAccessPolicy"
  description = "Policy to access secrets in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.guacamole_db_credentials.arn
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "secret_access_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.secret_access.arn
}


data "aws_region" "current" {}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"

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
  family                   = "guacamole"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = local.guac_container_name
      image     = "guacamole/guacamole"
      essential = true
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080
        }
      ],
      environment = [
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
      ],
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
          "awslogs-group"         = "/ecs/guacamole",
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "guacamole"
        }
      }
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
      volumesFrom = []
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/guacamole",
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = "guacd"
        }
      }
    }
  ])
}

resource "aws_lb" "guacamole_lb" {
  name               = "guacamole-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false
}

# Look up hosted zone id by name
data "aws_route53_zone" "zone" {
  name = var.hosted_zone_name
}

# DNS record
resource "aws_route53_record" "guacamole" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "guac.${var.hosted_zone_name}"
  type    = "A"
  alias {
    name                   = aws_lb.guacamole_lb.dns_name
    zone_id                = aws_lb.guacamole_lb.zone_id
    evaluate_target_health = false
  }
}


resource "aws_lb_listener" "http" {
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.guacamole_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.guacamole_tg.arn
  }
}

resource "aws_lb_listener_rule" "redirect_root" {
  listener_arn = aws_lb_listener.https.arn
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
  name        = "guacamole-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.this.id
  target_type = "ip"

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400 # 86400 seconds = 1 day.
  }
}

resource "aws_cloudwatch_log_group" "guacamole_log_group" {
  name = "/ecs/guacamole"
}

resource "aws_ecs_cluster" "fargate_cluster" {
  name = "guacamole"
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Security group for ECS Tasks"
  vpc_id      = data.aws_vpc.this.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = data.aws_subnet.private_subnets.*.cidr_block
  }
}

resource "aws_ecs_service" "guacamole" {
  depends_on      = [null_resource.db_init]
  name            = "guacamole"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.guacamole.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.guacamole_tg.arn
    container_name   = local.guac_container_name
    container_port   = 8080
  }
}

resource "aws_appautoscaling_target" "guacamole_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.fargate_cluster.name}/${aws_ecs_service.guacamole.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "guacamole_policy" {
  name               = "guacamole_policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.guacamole_target.resource_id
  scalable_dimension = aws_appautoscaling_target.guacamole_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.guacamole_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 75.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
