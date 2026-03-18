resource "aws_dynamodb_table" "this" {
  name           = var.table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = module.dynamodb_kms_key.key_arn
  }

  tags = {
    Name        = var.table_name
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      read_capacity,
      write_capacity,
    ]
  }

}

resource "aws_vpc_endpoint" "this" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.dynamodb"

  tags = {
    Environment = var.environment
  }

  route_table_ids = var.route_table_ids
}

locals {
  read_max_capacity  = var.environment == "prod" ? 20000 : 20
  write_max_capacity = var.environment == "prod" ? 1000 : 20
}


resource "aws_appautoscaling_target" "user_credentials_table_read_target" {
  max_capacity       = local.read_max_capacity
  min_capacity       = 1
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_target" "user_credentials_table_write_target" {
  max_capacity       = local.write_max_capacity
  min_capacity       = 1
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "user_credentials_table_read_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.user_credentials_table_read_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.user_credentials_table_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.user_credentials_table_read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.user_credentials_table_read_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = 70
  }
}

resource "aws_appautoscaling_policy" "user_credentials_table_write_policy" {
  name               = "DynamoDBWriteCapacityUtilization:${aws_appautoscaling_target.user_credentials_table_write_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.user_credentials_table_write_target.resource_id
  scalable_dimension = aws_appautoscaling_target.user_credentials_table_write_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.user_credentials_table_write_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }

    target_value = 70
  }
}

