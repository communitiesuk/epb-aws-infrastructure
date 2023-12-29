# https://www.terraform.io/docs/providers/aws/r/iam_policy.html
#https://github.com/tmknom/terraform-aws-ecs-scheduled-task/blob/master/main.tf
resource "aws_iam_policy" "ecs_events" {
  name        = "${var.prefix}-ecs-events-policy"
  policy      = data.aws_iam_policy.ecs_events.policy
}

resource "aws_iam_role" "ecs_events" {
  name               = "${var.prefix}-ecs-events-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_events_assume_role_policy.json
}


data "aws_iam_policy_document" "ecs_events_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ecs_events" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

# https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
resource "aws_iam_role_policy_attachment" "ecs_events" {
  role       = aws_iam_role.ecs_events.name
  policy_arn = aws_iam_policy.ecs_events.arn
}
