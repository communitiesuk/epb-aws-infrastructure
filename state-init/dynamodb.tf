resource "aws_dynamodb_table" "epbr_dynamo_terraform_state" {
  name           = "epbr-${var.environment}-terraform-state"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
