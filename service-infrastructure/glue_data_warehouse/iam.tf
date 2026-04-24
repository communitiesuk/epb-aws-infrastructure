resource "aws_iam_role" "glueServiceRole" {
  name = "AWSGlueServiceRole-${var.prefix}-glue"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.glueServiceRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "output_bucket_read_policy_attachment" {
  policy_arn = var.output_bucket_read_policy
  role       = aws_iam_role.glueServiceRole.name
}

resource "aws_iam_role_policy_attachment" "output_bucket_write_policy_attachment" {
  policy_arn = var.output_bucket_write_policy
  role       = aws_iam_role.glueServiceRole.name
}

resource "aws_iam_role_policy" "s3_bucket_policy" {
  name = "${var.prefix}-glue-role-s3-policy"
  role = aws_iam_role.glueServiceRole.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject*",
          "s3:ListBucket",
          "s3:GetObject*",
          "s3:DeleteObject*",
          "s3:GetBucketLocation"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })

}

resource "aws_iam_policy" "s3_bucket_read" {
  name = "${var.prefix}-glue-s3-read"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.this.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "secret_access" {
  name = "${var.prefix}-glue-role-secret-access-db-creds-policy"
  role = aws_iam_role.glueServiceRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.glue_db_creds.id
      }
    ]
  })
}

resource "aws_iam_role_policy" "self_pass_role" {
  name = "${var.prefix}-glue-role-self-pass-role"
  role = aws_iam_role.glueServiceRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = aws_iam_role.glueServiceRole.arn
      }
    ]
  })
}

resource "aws_iam_role" "refresh_mvw_state_machine" {
  name = "${var.prefix}-refresh-mvw-state-machine"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "refresh_mvw_state_machine" {
  name = "${var.prefix}-refresh-mvw-state-machine"
  role = aws_iam_role.refresh_mvw_state_machine.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RunEcsTask"
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = var.ecs_task_arn
      },
      {
        Sid    = "TrackEcsTask"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTasks",
          "ecs:StopTask"
        ]
        Resource = "*"
      },
      {
        Sid    = "PassEcsRoles"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          var.ecs_task_role_arn,
          var.ecs_task_execution_role_arn
        ]
        Condition = {
          StringLike = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        Sid    = "RunAllGluePopulateJobs"
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Resource = [for workflow in values(local.mvw_refresh_workflows) : workflow.glue_job_arn]
      },
      {
        Sid    = "ManageStepFunctionsEventBridgeRules"
        Effect = "Allow"
        Action = [
          "events:PutRule",
          "events:PutTargets",
          "events:DescribeRule",
          "events:RemoveTargets",
          "events:DeleteRule"
        ]
        Resource = "arn:aws:events:*:*:rule/StepFunctionsGetEventsFor*"
      }
    ]
  })
}
