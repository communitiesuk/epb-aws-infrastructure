locals {
  ecs_rake_command = ["bundle", "exec", "rake", "refresh_materialized_view"]
  domestic_state_machine_definition = jsonencode({
    Comment = "Orchestrate materialized view refresh → Glue populate job → Glue delete job"
    StartAt = "RefreshMaterializedViews"

    States = {

      RefreshMaterializedViews = {
        Type = "Parallel"

        Branches = [

          {
            StartAt = "RefreshMaterializedView"

            States = {
              RefreshMaterializedView = {
                Type     = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"

                Parameters = {
                  Cluster        = var.ecs_cluster_arn
                  TaskDefinition = var.ecs_task_definition_arn
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
                        Command = local.ecs_rake_command
                        Environment = [
                          {
                            Name  = "NAME"
                            Value = var.ecs_materialized_view_name
                          }
                        ]
                      }
                    ]
                  }
                }

                End = true
              }
            }
          },
          {
            StartAt = "RefreshRecommendationsMaterializedView"

            States = {
              RefreshRecommendationsMaterializedView = {
                Type     = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"

                Parameters = {
                  Cluster        = var.ecs_cluster_arn
                  TaskDefinition = var.ecs_task_definition_arn
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
                        Command = local.ecs_rake_command
                        Environment = [
                          {
                            Name  = "NAME"
                            Value = var.ecs_rr_materialized_view_name
                          }
                        ]
                      }
                    ]
                  }
                }

                End = true
              }
            }
          }
        ]
        Next = "RunPopulateJobs"
      }


      RunPopulateJobs = {
        Type = "Parallel"

        Branches = [
          {
            StartAt = "RunPopulateJob"

            States = {
              RunPopulateJob = {
                Type     = "Task"
                Resource = "arn:aws:states:::glue:startJobRun.sync"

                Parameters = {
                  JobName = var.glue_populate_job_name
                  Arguments = {
                    "--job-language" = "python"
                  }
                }

                End = true
              }
            }
          },

          {
            StartAt = "RunPopulateRecommendationsJob"

            States = {
              RunPopulateRecommendationsJob = {
                Type     = "Task"
                Resource = "arn:aws:states:::glue:startJobRun.sync"

                Parameters = {
                  JobName = var.glue_populate_rr_job_name
                  Arguments = {
                    "--job-language" = "python"
                  }
                }

                End = true
              }
            }
          }
        ]
        Next = "RunDeleteJob"
      }


      RunDeleteJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"

        Parameters = {
          JobName = var.glue_delete_job_name
          Arguments = {
            "--job-language" = "python"
          }
        }

        Next = "RunZipExportJob"
      }

      RunZipExportJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"

        Parameters = {
          JobName = var.glue_zip_export_job_name
          Arguments = {
            "--job-language" = "python"
          }
        }

        Next = "JobSucceeded"
      }

      JobSucceeded = {
        Type = "Succeed"
      }
    }
  })
}

resource "aws_sfn_state_machine" "this" {
  name     = "${var.prefix}-view-refresh-orchestration"
  role_arn = aws_iam_role.step_function_role.arn

  type       = "STANDARD"
  definition = local.domestic_state_machine_definition
}
