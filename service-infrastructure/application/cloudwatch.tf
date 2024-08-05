# AWS EventBridge rule
resource "aws_cloudwatch_event_rule" "ecs_events" {
  name        = "${var.prefix}-ecs-events"
  description = "${var.prefix} capture all ECS events "

  event_pattern = jsonencode({
    "source" : ["aws.ecs"],
    "detail" : {
      "clusterArn" : [aws_ecs_cluster.this.arn]
    }
  })
}

# AWS EventBridge target
resource "aws_cloudwatch_event_target" "logs" {
  rule      = aws_cloudwatch_event_rule.ecs_events.name
  target_id = "${var.prefix}-send-to-cloudwatch"
  arn       = var.cloudwatch_ecs_events_arn
}

