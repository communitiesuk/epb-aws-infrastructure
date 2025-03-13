resource "aws_glue_catalog_database" "this" {
  name = "${var.prefix}-glue-catalog"
}

