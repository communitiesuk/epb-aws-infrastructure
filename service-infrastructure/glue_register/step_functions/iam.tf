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
      values   = ["arn:aws:states:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:stateMachine:*"]
    }
  }
}

data "aws_iam_policy_document" "step_function_permissions" {

  statement {
    sid = "StartGlueJobs"
    actions = [
      "glue:StartJobRun",
      "glue:GetJobRun",
      "glue:GetJobRuns",
      "glue:BatchStopJobRun",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:job/${var.glue_update_created_at_name}",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:job/${var.glue_update_status_name}",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:job/${var.glue_update_address_id_name}",
      "arn:aws:glue:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:job/${var.glue_green_deals_name}",
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
