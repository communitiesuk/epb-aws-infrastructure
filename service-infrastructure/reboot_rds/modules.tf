module "aurora" {
  count                       = (var.schedule_enabled == true && var.rds_reboot_aurora_instances != null) ? 1 : 0
  source                      = "./aurora"
  prefix                      = var.prefix
  rds_reboot_aurora_instances = var.rds_reboot_aurora_instances
}

module "rds" {
  count               = (var.schedule_enabled == true && var.rds_reboot_instance != null) ? 1 : 0
  source              = "./rds"
  prefix              = var.prefix
  rds_reboot_instance = var.rds_reboot_instance
}