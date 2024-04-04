

locals {
  task_config = {
    cluster_arn       = var.cluster_arn
    security_group_id = var.security_group_id
    vpc_subnet_ids    = var.vpc_subnet_ids
    task_arn          = var.task_arn
    event_role_arn    = var.event_rule_arn
    container_name    = var.container_name
  }
  ode_export = "for_odc"
}

module "save_previous_day_statistics_job" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "save-previous-day-statistics-job"
  task_config         = local.task_config
  schedule_expression = "cron(0 3 * * ? *)"
  command             = ["bundle", "exec", "rake", "maintenance:daily_statistics"]
}

module "post_previous_day_statistics_to_slack_job" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "post-previous-day-statistics-to-slack-job"
  task_config         = local.task_config
  schedule_expression = "cron(30 9 * * ? *)"
  command             = ["bundle", "exec", "rake", "maintenance:post_previous_day_statistics"]
}

module "update_address_base" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "update-address-base"
  task_config         = local.task_config
  schedule_expression = "cron(15 4 * * ? *)"
  command             = ["npm", "run", "update-address-base-auto"]
}

module "import_green_deal_fuel_price_data" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "import-green-deal-fuel-price-data"
  task_config         = local.task_config
  schedule_expression = "cron(13 2 2 * ? *)"
  command             = ["bundle", "exec", "rake", "maintenance:green_deal_update_fuel_data"]
}

module "export_invoice_scheme_name_type" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "export-invoice-scheme-name-type"
  task_config         = local.task_config
  schedule_expression = "cron(56 6 1 * ? *)"
  command             = ["bundle", "exec", "rake", "data_export:export_invoices"]
  environment = [
    {
      "name" : "report_type",
      "value" : "scheme_name_type"
    },
  ]
}

module "export_invoice_region_type" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "export-invoice-region-type"
  task_config         = local.task_config
  schedule_expression = "cron(57 6 1 * ? *)"
  command             = ["bundle", "exec", "rake", "data_export:export_invoices"]
  environment = [
    {
      "name" : "report_type",
      "value" : "region_type"
    },
  ]
}

module "export_invoices_by_assessment_scheme" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "export-invoices-by-assessment-scheme"
  task_config         = local.task_config
  schedule_expression = "cron(58 6 1 * ? *)"
  command             = ["bundle", "exec", "rake", "data_export:export_schema_invoices"]
}

module "domestic_open_data_export" {
  source              = "../scheduled_tasks/event_rule"
  task_config         = local.task_config
  prefix              = var.prefix
  rule_name           = "domestic-open-data-export"
  schedule_expression = "cron(30 3 1 * ? *)"
  command             = ["bundle", "exec", "rake", "open_data:export_assessments"]
  environment = [
    {
      "name" : "type_of_export",
      "value" : local.ode_export
    },
    {
      "name" : "assessment_type",
      "value" : "SAP-RDSAP"
    },
  ]
}

module "commercial_open_data_export" {
  source              = "../scheduled_tasks/event_rule"
  task_config         = local.task_config
  prefix              = var.prefix
  rule_name           = "cepc-open-data-export"
  schedule_expression = "cron(40 4 1 * ? *)"
  command             = ["bundle", "exec", "rake", "open_data:export_assessments"]
  environment = [
    {
      "name" : "type_of_export",
      "value" : local.ode_export
    },
    {
      "name" : "assessment_type",
      "value" : "CEPC"
    },
  ]
}

module "dec_open_data_export" {
  source              = "../scheduled_tasks/event_rule"
  task_config         = local.task_config
  prefix              = var.prefix
  rule_name           = "dec-open-data-export"
  schedule_expression = "cron(59 4 1 * ? *)"
  command             = ["bundle", "exec", "rake", "open_data:export_assessments"]
  environment = [
    {
      "name" : "type_of_export",
      "value" : local.ode_export
    },
    {
      "name" : "assessment_type",
      "value" : "DEC"
    },
  ]
}

module "commercial_recommendations_open_data_export" {
  source              = "../scheduled_tasks/event_rule"
  task_config         = local.task_config
  prefix              = var.prefix
  rule_name           = "commercial-recommendations-open-data-export"
  schedule_expression = "cron(30 5 1 * ? *)"
  command             = ["bundle", "exec", "rake", "open_data:export_assessments"]
  environment = [
    {
      "name" : "type_of_export",
      "value" : local.ode_export
    },
    {
      "name" : "assessment_type",
      "value" : "CEPC-RR"
    },
  ]
}

module "dec_recommendations_open_data_export" {
  source              = "../scheduled_tasks/event_rule"
  task_config         = local.task_config
  prefix              = var.prefix
  rule_name           = "dec-recommendations-open-data-export"
  schedule_expression = "cron(35 5 1 * ? *)"
  command             = ["bundle", "exec", "rake", "open_data:export_assessments"]
  environment = [
    {
      "name" : "type_of_export",
      "value" : local.ode_export
    },
    {
      "name" : "assessment_type",
      "value" : "DEC-RR"
    },
  ]
}

module "domestic_recommendations_open_data_export" {
  source              = "../scheduled_tasks/event_rule"
  task_config         = local.task_config
  prefix              = var.prefix
  rule_name           = "domestic-recommendations-open-data-export"
  schedule_expression = "cron(37 5 1 * ? *)"
  command             = ["bundle", "exec", "rake", "open_data:export_assessments"]
  environment = [
    {
      "name" : "type_of_export",
      "value" : local.ode_export
    },
    {
      "name" : "assessment_type",
      "value" : "SAP-RDSAP-RR"
    },
  ]
}

module "export_not_for_publication" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "schedule-export-not-for-publication"
  schedule_expression = "cron(35 5 1 * ? *)"
  task_config         = local.task_config
  command             = ["bundle", "exec", "rake", "open_data:export_not_for_publication"]
  environment = [
    {
      "name" : "type_of_export",
      "value" : local.ode_export
    },
    {
      "name" : "ODE_BUCKET_NAME",
      "value" : "${var.prefix}-open-data-export"
    },
  ]
}