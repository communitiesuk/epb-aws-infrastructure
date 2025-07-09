resource "aws_glue_workflow" "iceberg_daily_update" {
  name = "${local.prefix}_glue_workflow_daily_updates"
}

resource "aws_glue_trigger" "trigger_delete" {
  name          = "trigger-delete"
  type          = "SCHEDULED"
  schedule      = "cron(1 0 * * ? *)" # Runs at 00:01 UTC every day
  workflow_name = aws_glue_workflow.iceberg_daily_update.name

  actions {
    job_name = module.delete_iceberg_data.etl_job_name
  }
}

resource "aws_glue_trigger" "trigger_insert" {
  name          = "trigger-insert"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.iceberg_daily_update.name

  actions {
    job_name = module.insert_domestic_iceberg_data.etl_job_name
  }

  actions {
    job_name = module.insert_domestic_rr_iceberg_data.etl_job_name
  }

  predicate {
    conditions {
      job_name = module.delete_iceberg_data.etl_job_name
      state    = "SUCCEEDED"
    }
  }
}
