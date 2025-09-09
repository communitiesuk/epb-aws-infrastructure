resource "aws_glue_workflow" "addressing_daily_update" {
  name = "${var.prefix}-addressing-daily-update"
}

resource "aws_glue_trigger" "load_csv_to_s3_trigger" {
  name          = "load-csv-to-s3-trigger"
  type          = "SCHEDULED"
  schedule      = "cron(1 0 * * ? *)" # Runs at 00:01 UTC every day
  workflow_name = aws_glue_workflow.addressing_daily_update.name

  actions {
    job_name = module.load_ngd_csvs_into_s3_etl.etl_job_name
  }
}
