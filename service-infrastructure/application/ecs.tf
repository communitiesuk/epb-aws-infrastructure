locals {
  container_name                 = "${var.prefix}-container"
  fluentbit_container_name       = "${var.prefix}-container-fluentbit"
  migration_container_name       = "${var.prefix}-container-db-migration"
  ecr_image                      = local.has_ecr == 1 ? "${aws_ecr_repository.this[0].repository_url}:latest" : var.external_ecr
  has_address_base_updater_image = var.address_base_updater_ecr != null ? true : false
  address_base_container_name    = "${var.prefix}-container-address-base-updater"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-cluster"

  lifecycle {
    prevent_destroy = true
  }

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE_SPOT", "FARGATE"]
}

resource "aws_ecs_task_definition" "this" {
  count                    = var.has_start_task == true ? 1 : 0
  family                   = "${var.prefix}-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = local.ecr_image
      essential = true

      environment = [for key, value in var.environment_variables : {
        name  = key
        value = value
      } if value != ""]

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
        containerName = local.fluentbit_container_name
        condition     = "START"
      }]

      logConfiguration = {
        logDriver = "awsfirelens"
      }

      cpu         = 14
      mountPoints = []
      volumesFrom = []

      memoryReservation = 512

      stopTimeout = 90
    },
    {
      name      = local.fluentbit_container_name
      image     = "${var.fluentbit_ecr_url}:latest"
      cpu       = 0
      essential = var.is_fluentbit_container_essential

      environment = [
        { Name = "FLB_LOG_LEVEL", Value = "debug" },
        { Name = "LOG_LEVEL", Value = "debug" },
        { Name = "LOG_GROUP_NAME", Value = var.aws_cloudwatch_log_group_name },
        { Name = "LOG_STREAM_NAME", Value = var.prefix }
      ]

      secrets = [for value in ["LOGSTASH_HOST", "LOGSTASH_PORT"] : {
        name      = value
        valueFrom = var.parameters[value]
      }]

      firelensConfiguration = {
        type = "fluentbit"
        options = {
          "config-file-type"  = "file",
          "config-file-value" = "/fluent-bit.conf"
        }

      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.aws_cloudwatch_log_group_id
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs-fluentbit"
        }
      }

      healthcheck = {
        command     = ["CMD-SHELL", "curl -f http://127.0.0.1:2020/api/v1/health || exit 1"]
        interval    = 10
        retries     = 3
        startPeriod = 10
        timeout     = 5
      }

      mountPoints  = []
      portMappings = []
      user         = "0"
      volumesFrom  = []

      cpu               = 2
      memoryReservation = 512
      memory            = 850

      stopTimeout = 90
    },

  ])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_task_definition" "exec_cmd_task" {
  count                    = var.has_exec_cmd_task == true ? 1 : 0
  family                   = "${var.prefix}-ecs-exec-cmd-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.exec_cmd_task_cpu
  memory                   = var.exec_cmd_task_ram
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = local.migration_container_name
      image     = local.ecr_image
      essential = true
      environment = [for key, value in var.environment_variables : {
        name  = key
        value = value
      }]
      user = "root" #added to ensure paketo image defaults to root user
      secrets = [for key, value in merge(var.secrets, var.parameters) : {
        name      = key
        valueFrom = value
      }]
      entryPoint  = ["launcher"]
      command     = ["bundle", "exec", "rake", "db:migrate"]
      cpu         = 0
      mountPoints = []
      volumesFrom = []

      memoryReservation = 512

      stopTimeout = 90

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.aws_cloudwatch_log_group_id
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs-exec-cmd"
        }
      }
    },
  ])
}

resource "aws_ecs_task_definition" "address_base_updater_task" {
  count                    = local.has_address_base_updater_image == true ? 1 : 0
  family                   = "${var.prefix}-ecs-address-base-updater-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.exec_cmd_task_cpu
  memory                   = var.exec_cmd_task_ram
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = local.address_base_container_name
      image     = "${var.address_base_updater_ecr}:latest"
      essential = true
      environment = [for key, value in var.environment_variables : {
        name  = key
        value = value
      }]
      user = "root" #added to ensure paketo image defaults to root user
      secrets = [for key, value in merge(var.secrets, var.parameters) : {
        name      = key
        valueFrom = value
      }]
      entryPoint  = ["launcher"]
      command     = ["npm", "run", "update-address-base-auto"]
      cpu         = 0
      mountPoints = []
      volumesFrom = []

      memoryReservation = 512

      stopTimeout = 90

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.aws_cloudwatch_log_group_id
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs-address-base-updater"
        }
      }
    },
  ])
}

resource "aws_ecs_service" "this" {
  count                              = var.has_start_task == true ? 1 : 0
  name                               = var.prefix
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = try(aws_ecs_task_definition.this[0].arn, null)
  desired_count                      = var.task_desired_capacity
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = 200
  scheduling_strategy                = "REPLICA"
  enable_execute_command             = var.enable_execute_command
  health_check_grace_period_seconds  = var.front_door_config != null ? 60 : null

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = var.fargate_weighting.standard
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = var.fargate_weighting.spot
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.front_door_config != null ? [0] : []

    content {
      target_group_arn = module.front_door[0].lb_target_group_arn
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }

  # associate any extra load balancer target groups to the ECS container
  dynamic "load_balancer" {
    for_each = var.front_door_config != null ? module.front_door[0].lb_extra_target_group_arns : []

    content {
      target_group_arn = load_balancer.value
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }

  dynamic "load_balancer" {
    for_each = local.create_internal_alb ? [0] : []

    content {
      target_group_arn = aws_lb_target_group.internal[0].arn
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }

  lifecycle {
    ignore_changes        = [desired_count]
    create_before_destroy = true
    prevent_destroy       = true
  }

  force_new_deployment = true
}
