locals {
  mvw_refresh_workflows = {
    domestic = {
      materialized_view_name = "mvw_domestic_search"
      glue_job_name          = module.populate_domestic_etl.etl_job_name
      glue_job_arn           = module.populate_domestic_etl.etl_job_arn
    }
    domestic_rr = {
      materialized_view_name = "mvw_domestic_rr_search"
      glue_job_name          = module.populate_domestic_rr_etl.etl_job_name
      glue_job_arn           = module.populate_domestic_rr_etl.etl_job_arn
    }
    commercial = {
      materialized_view_name = "mvw_commercial_search"
      glue_job_name          = module.populate_non_domestic_etl.etl_job_name
      glue_job_arn           = module.populate_non_domestic_etl.etl_job_arn
    }
    commercial_rr = {
      materialized_view_name = "mvw_commercial_rr_search"
      glue_job_name          = module.populate_non_domestic_rr_etl.etl_job_name
      glue_job_arn           = module.populate_non_domestic_rr_etl.etl_job_arn
    }
    dec = {
      materialized_view_name = "mvw_dec_search"
      glue_job_name          = module.populate_dec_etl.etl_job_name
      glue_job_arn           = module.populate_dec_etl.etl_job_arn
    }
    dec_rr = {
      materialized_view_name = "mvw_dec_rr_search"
      glue_job_name          = module.populate_dec_rr_etl.etl_job_name
      glue_job_arn           = module.populate_dec_rr_etl.etl_job_arn
    }
  }
}

resource "aws_sfn_state_machine" "refresh_mvw_then_populate" {
  for_each = local.mvw_refresh_workflows

  name     = "${var.prefix}-refresh-${each.key}-mvw-then-populate"
  role_arn = aws_iam_role.refresh_mvw_state_machine.arn

  definition = jsonencode({
    Comment = "Refresh ${each.value.materialized_view_name} then run ${each.value.glue_job_name} Glue job"
    StartAt = "RefreshMaterializedView"
    States = {
      RefreshMaterializedView = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          Cluster        = var.ecs_cluster_arn
          TaskDefinition = var.ecs_task_arn
          LaunchType     = "FARGATE"
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = var.ecs_subnet_ids
              SecurityGroups = [var.ecs_security_group_id]
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name    = var.ecs_container_name
                Command = ["bundle", "exec", "rake", "refresh_materialized_view"]
                Environment = [
                  {
                    Name  = "NAME"
                    Value = each.value.materialized_view_name
                  }
                ]
              }
            ]
          }
        }
        Next = "PopulateGlueJob"
      }
      PopulateGlueJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = each.value.glue_job_name
        }
        End = true
      }
    }
  })
}
