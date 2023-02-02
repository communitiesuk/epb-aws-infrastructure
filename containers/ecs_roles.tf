resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}-ecsTaskRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

# TODO add ARN for RDS resource once defined
resource "aws_iam_policy" "rds" {
  name        = "${var.prefix}-task-policy-rds"
  description = "Policy that allows access to RDS"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Action": "rds:*",
         "Resource": "arn:aws:rds:${var.region}:123456789012:db:mydb"
      }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.rds.arn
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.prefix}-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}