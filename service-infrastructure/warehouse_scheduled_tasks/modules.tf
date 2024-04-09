locals {
  task_config = {
    cluster_arn       = var.cluster_arn
    security_group_id = var.security_group_id
    vpc_subnet_ids    = var.vpc_subnet_ids
    task_arn          = var.task_arn
    event_role_arn    = var.event_rule_arn
    container_name    = var.container_name
  }
}

module "send_heat_pump_count_by_property_type" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "send-heat-pump-count-by-property-type"
  task_config         = local.task_config
  schedule_expression = "cron(25 04 1 * ? *)"
  command             = ["bundle", "exec", "rake", "email_heat_pump_data"]
  environment = [
    {
      "name" : "TYPE_OF_EXPORT",
      "value" : "property_type"
    },
  ]
}

module "send_heat_pump_count_by_floor_area" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "send-heat-pump-count-by-floor-area"
  task_config         = local.task_config
  schedule_expression = "cron(35 04 1 * ? *)"
  command             = ["bundle", "exec", "rake", "email_heat_pump_data"]
  environment = [
    {
      "name" : "TYPE_OF_EXPORT",
      "value" : "floor_area"
    },
  ]
}

module "send_heat_pump_count_by_local_authority" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "send-heat-pump-count-by-local-authority"
  task_config         = local.task_config
  schedule_expression = "cron(45 04 1 * ? *)"
  command             = ["bundle", "exec", "rake", "email_heat_pump_data"]
  environment = [
    {
      "name" : "TYPE_OF_EXPORT",
      "value" : "local_authority"
    },
  ]
}

module "send_heat_pump_count_by_parliamentary_constituency" {
  source              = "../scheduled_tasks/event_rule"
  prefix              = var.prefix
  rule_name           = "send-heat-pump-count-by-parliamentary-constituency"
  task_config         = local.task_config
  schedule_expression = "cron(53 04 1 * ? *)"
  command             = ["bundle", "exec", "rake", "email_heat_pump_data"]
  environment = [
    {
      "name" : "TYPE_OF_EXPORT",
      "value" : "parliamentary_constituency"
    },
  ]
}

