resource "aws_sfn_state_machine" "glue_orchestration" {
  name     = "${var.prefix}-orchestration"
  role_arn = aws_iam_role.step_function_role.arn

  type = "STANDARD"

  definition = jsonencode({
    Comment = "Run the three Glue jobs to update assessment metadata for each supplied input set, then run one final Glue job to insert green deals"

    StartAt = "Process input sets"

    States = {
      "Process input sets" = {
        Type           = "Map"
        ItemsPath      = "$.s3_path_assessment_metadata"
        MaxConcurrency = 1

        ItemProcessor = {
          ProcessorConfig = {
            Mode = "INLINE"
          }

          StartAt = "Update createdAt"

          States = {
            "Update createdAt" = {
              Type     = "Task"
              Resource = "arn:aws:states:::glue:startJobRun.sync"

              Parameters = {
                JobName = var.glue_update_created_at_name

                Arguments = {
                  "--INPUT_S3_PATH.$" = "$"
                }
              }

              ResultPath = null
              Next       = "Update certificate status"
            }

            "Update certificate status" = {
              Type     = "Task"
              Resource = "arn:aws:states:::glue:startJobRun.sync"

              Parameters = {
                JobName = var.glue_update_status_name

                Arguments = {
                  "--INPUT_S3_PATH.$" = "$"
                }
              }

              ResultPath = null
              Next       = "Update addressId"
            }

            "Update addressId" = {
              Type     = "Task"
              Resource = "arn:aws:states:::glue:startJobRun.sync"

              Parameters = {
                JobName = var.glue_update_address_id_name

                Arguments = {
                  "--INPUT_S3_PATH.$" = "$"
                }
              }

              ResultPath = null
              End        = true
            }
          }
        }

        ResultPath = null
        Next       = "Insert green deals"
      }

      "Insert green deals" = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"

        Parameters = {
          JobName = var.glue_green_deals_name

          Arguments = {
            "--INPUT_S3_PATH_GDPlans.$" = "$.green_deals.s3_path_GDPlans"
            "--INPUT_S3_PATH_GD_P.$"    = "$.green_deals.s3_path_GD_P"
            "--INPUT_S3_PATH_GDPM.$"    = "$.green_deals.s3_path_GDPM"
            "--INPUT_S3_PATH_GDPS.$"    = "$.green_deals.s3_path_GDPS"
            "--INPUT_S3_PATH_GDPDC.$"   = "$.green_deals.s3_path_GDPDC"
            "--RANDOMISE_PLAN_IDS.$"    = "$.green_deals.randomise_plan_ids"
          }
        }

        ResultPath = null
        End        = true

        Retry = [
          {
            ErrorEquals = [
              "Glue.ConcurrentRunsExceededException",
              "Glue.InternalServiceException",
              "Glue.OperationTimeoutException",
              "States.TaskFailed"
            ]

            IntervalSeconds = 30
            BackoffRate     = 2
            MaxAttempts     = 3
          }
        ]
      }
    }
  })
}
