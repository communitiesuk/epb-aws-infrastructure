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

  actions {
    job_name = module.insert_json_document_iceberg_data.etl_job_name
  }

  predicate {
    conditions {
      job_name = module.delete_iceberg_data.etl_job_name
      state    = "SUCCEEDED"
    }
  }
}

resource "aws_glue_workflow" "domestic_monthly_export" {
  name = "${local.prefix}_glue_workflow_domestic_monthly_export"
}

resource "aws_glue_trigger" "trigger_domestic_monthly_export" {
  name          = "trigger-domestic-monthly-export"
  type          = "SCHEDULED"
  schedule      = "cron(30 0 1 * ? *)" # Runs at 00:30 UTC on the 1st of every month
  workflow_name = aws_glue_workflow.domestic_monthly_export.name

  actions {
    job_name = module.export_domestic_data_by_year.etl_job_name
  }

  actions {
    job_name = module.export_json_domestic_data_by_year.etl_job_name
  }
}

# Chain populate domestic_json_document jobs:
resource "aws_glue_workflow" "populate_json_documents" {
  name = "${local.prefix}_populate_json_documents"
}

# First job to be triggered manually. If 'enabled' it will be triggered
# automatically before terraform finishes creating all the triggers
resource "aws_glue_trigger" "populate_json_documents_trigger" {
  name          = "populate_json_documents_trigger_0"
  type          = "ON_DEMAND"
  enabled       = false
  workflow_name = aws_glue_workflow.populate_json_documents.name

  actions {
    job_name = module.populate_json_documents_etl[0].etl_job_name
  }
}

resource "aws_glue_trigger" "populate_json_documents_chain" {
  count         = local.number_years
  name          = "populate_json_documents_trigger_${count.index + 1}"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.populate_json_documents.name

  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name         = module.populate_json_documents_etl[count.index].etl_job_name
      state            = "SUCCEEDED"
    }
  }

  actions {
    job_name = module.populate_json_documents_etl[count.index + 1].etl_job_name
  }
}
