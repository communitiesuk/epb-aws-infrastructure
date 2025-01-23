resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.prefix}-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "${var.prefix}-container"
      image     = "${aws_ecr_repository.this.repository_url}:latest"
      essential = true

      environment = [

      ]

      portMappings = [
        {
          protocol      = "tcp"
          containerPort = 80
          hostPort      = 80
        }
      ]

      cpu         = 0
      mountPoints = []
      volumesFrom = []

      memoryReservation = 512

      secrets = [for key, value in var.environment_variables : {
        name      = key
        valueFrom = value
      }]

      environment = [
        { Name = "NODE_ENV", Value = "production" },
      ]

    },

  ])
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_service" "this" {
  name                               = var.prefix
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"


  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.private_subnet[*].id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.public.arn
    container_name   = "${var.prefix}-container"
    container_port   = 80
  }

  depends_on = []

  lifecycle {
    ignore_changes = [desired_count]
  }

  force_new_deployment = true
}
