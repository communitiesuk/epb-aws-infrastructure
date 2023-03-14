locals {
  container_name = "${var.prefix}-container"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.prefix}-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name        = local.container_name
      image       = "${aws_ecr_repository.this.repository_url}:latest"
      essential   = true
      environment = var.environment_variables
      secrets = [for key, value in merge(var.secrets, var.parameters) : {
        name      = key
        valueFrom = value
      }]
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
      dependsOn = [{
        containerName = "${local.container_name}_fluentbit"
        condition     = "START"
      }]
      logConfiguration = {
        logDriver = "awsfirelens",
        options = {
          Name         = "http"
          Match        = "*"
          aws_region   = var.region
          Format       = "json"
          tls          = "On"
          "tls.verify" = "Off"
        }
        secretOptions = [for key, value in {
          Host = "LOGSTASH_HOST"
          Port = "LOGSTASH_PORT"
          } : {
          name      = key
          valueFrom = var.parameters[value]
        }]
      }
      cpu         = 0
      mountPoints = []
      volumesFrom = []
    },
    {
      name  = "${local.container_name}_fluentbit"
      image = "public.ecr.aws/aws-observability/aws-for-fluent-bit:stable",
      cpu   = 0
      firelensConfiguration = {
        type = "fluentbit"
      }
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.aws_cloudwatch_log_group_id,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs_fluentbit"
        }
      }
      environment  = []
      mountPoints  = []
      portMappings = []
      user         = "0"
      volumesFrom  = []
    }
  ])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}

resource "aws_ecs_service" "this" {
  name                               = var.prefix
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.public.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  dynamic "load_balancer" {
    for_each = local.create_internal_alb ? [0] : []

    content {
      target_group_arn = aws_lb_target_group.internal[0].arn // update
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}