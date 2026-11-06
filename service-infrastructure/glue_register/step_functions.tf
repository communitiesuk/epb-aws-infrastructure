module "update_all_scottish_metadata" {
  source = "./step_functions"
  prefix = "${var.prefix}-update-scottish-metadata"

  glue_update_created_at_name = module.update_scottish_created_at_date.etl_job_name
  glue_update_status_name     = module.update_scottish_status.etl_job_name
  glue_update_address_id_name = module.update_scottish_address_ids.etl_job_name
  glue_green_deals_name       = module.insert_scottish_green_deals.etl_job_name
}
