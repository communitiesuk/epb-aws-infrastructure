resource "aws_iam_role" "step_function_role" {
  name               = "${var.prefix}-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

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
      values   = ["arn:aws:states:${var.region}:${data.aws_caller_identity.current.account_id}:stateMachine:*"]
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "step_function_ecs_task_access" {
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
      "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task/${split("/", var.ecs_cluster_arn)[1]}/*"
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
}

resource "aws_iam_policy" "step_function_ecs_task_access" {
  name   = "${var.prefix}-sfn-ecs-policy"
  policy = data.aws_iam_policy_document.step_function_ecs_task_access.json
}

resource "aws_iam_role_policy_attachment" "step_function_ecs_task_access" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_ecs_task_access.arn
}

# EventBridge permissions used by Step Functions .sync integrations.
data "aws_iam_policy_document" "step_function_event_bridge_access" {
  statement {
    sid = "EventBridgeSync"
    actions = [
      "events:PutTargets",
      "events:PutRule",
      "events:DescribeRule",
    ]
    resources = [
      "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule",
      "arn:aws:events:${var.region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForGlueJobRule"
    ]
  }
}

resource "aws_iam_policy" "step_function_event_bridge_access" {
  name   = "${var.prefix}-sfn-eventbridge-policy"
  policy = data.aws_iam_policy_document.step_function_event_bridge_access.json
}

resource "aws_iam_role_policy_attachment" "step_function_event_bridge_access" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_event_bridge_access.arn
}

data "aws_iam_policy_document" "step_function_glue_access" {
  statement {
    sid = "StartGlueJobs"
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:BatchStopJobRun",
    ]
    resources = [
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.glue_populate_job_name}",
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.glue_delete_job_name}",
      "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.glue_zip_export_job_name}",
    ]
  }
}

resource "aws_iam_policy" "step_function_glue_access" {
  name   = "${var.prefix}-sfn-glue-policy"
  policy = data.aws_iam_policy_document.step_function_glue_access.json
}

resource "aws_iam_role_policy_attachment" "step_function_glue_access" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_glue_access.arn
}