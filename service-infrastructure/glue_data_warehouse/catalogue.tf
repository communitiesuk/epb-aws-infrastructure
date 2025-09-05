locals {
  prefix = replace(var.prefix, "-", "_")
}

resource "aws_glue_catalog_database" "this" {
  name = "${local.prefix}_glue_catalog"
}

