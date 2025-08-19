resource "aws_dynamodb_table" "epb_data_credentials" {
  name           = "${var.prefix}-data-credentials"
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
    kms_key_arn = var.kms_key_arn
  }

  tags = {
    Name        = "${var.prefix}-data-credentials"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "this" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.${var.dynamodb_service_name}"

  tags = {
    Environment = var.environment
  }

  route_table_ids = var.route_table_ids
}