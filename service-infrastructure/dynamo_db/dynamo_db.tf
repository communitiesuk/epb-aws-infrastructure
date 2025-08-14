resource "aws_dynamodb_table" "epb_data_credentials" {
  name           = "epb_${var.environment}_data_credentials"
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
    Name        = "epb-${var.environment}-data-credentials"
    Environment = var.environment
  }
}

