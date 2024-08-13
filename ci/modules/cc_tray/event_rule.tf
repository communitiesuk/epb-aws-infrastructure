resource "aws_cloudwatch_event_rule" "this" {
  name        = var.app_name
  description = "Rule that matches CodePipeline State Execution State Changes"

  event_pattern = jsonencode(
    {
      "detail-type" : ["CodePipeline Stage Execution State Change"],
      "source" : ["aws.codepipeline"]
  })

}

resource "aws_cloudwatch_event_target" "this" {
  target_id = var.app_name
  rule      = aws_cloudwatch_event_rule.this.name
  arn       = aws_lambda_function.this.arn
}
