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
      name      = "${var.prefix}-container"
      image     = "${var.ecr_repository_url}:latest"
      essential = true
      environment = [
        {
          name  = "BUCKET_NAME",
          value = var.backup_bucket_name
        },
        {
          name  = "BACKUP_FILE",
          value = var.backup_file
        }
      ]
      secrets = [
        {
          name      = "DATABASE_URL",
          valueFrom = var.rds_db_connection_string_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = var.log_group,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      }
  }])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}