data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    # Restrict to this region/account to prevent confused deputy
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:*"]
    }
  }
}

data "aws_iam_policy_document" "step_function_permissions" {
  statement {
    sid     = "RunECSTask"
    actions = ["ecs:RunTask"]
    resources = [
      replace(var.ecs_task_definition_arn, "/:[0-9]+$/", ":*"),
      var.ecs_task_definition_arn,
    ]
  }

  statement {
    sid     = "ManageECSTask"
    actions = ["ecs:StopTask", "ecs:DescribeTasks"]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/${split("/", var.ecs_cluster_arn)[1]}/*"
    ]

  }

  statement {
    sid     = "PassRoleToECS"
    actions = ["iam:PassRole"]
    resources = [
      var.ecs_task_role_arn,
      var.ecs_task_execution_role_arn,
    ]
  }

  statement {
    sid = "StartGlueJobs"
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:BatchStopJobRun",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/${var.glue_populate_job_name}",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/${var.glue_populate_rr_job_name}",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/${var.glue_delete_job_name}",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job/${var.glue_zip_export_job_name}",
    ]
  }

  statement {
    sid = "EventBridgeSync"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]
    resources = [
      "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule",
      "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForGlueJobRule"
    ]
  }
}

resource "aws_iam_policy" "step_function_permissions_policy" {
  name        = "${var.prefix}-sfn-permissions-policy"
  description = "Consolidated execution permissions for the Step Function"
  policy      = data.aws_iam_policy_document.step_function_permissions.json
}

resource "aws_iam_role" "step_function_role" {
  name               = "${var.prefix}-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "step_function_permissions_attach" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_permissions_policy.arn
}