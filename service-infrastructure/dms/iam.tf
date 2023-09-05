resource "aws_iam_role" "dms_role" {
  name = "${var.prefix}-${var.name}-dms-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = [
            "dms-data-migrations.amazonaws.com",
            "dms.eu-west-2.amazonaws.com"
          ]
        }
        Effect = "Allow"
        Sid    = ""
      }
    ]
  })

}

resource "aws_iam_policy" "dms_policy" {
  name = "${var.prefix}-${var.name}-dms-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeVpcs",
          "ec2:DescribePrefixLists",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "servicequotas:GetServiceQuota"
        ],
        "Resource" : "arn:aws:servicequotas:*:*:vpc/L-0EA8095F"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ],
        "Resource" : "arn:aws:logs:*:*:log-group:dms-data-migration-*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:log-group:dms-data-migration-*:log-stream:dms-data-migration-*"
      },
      {
        "Effect" : "Allow",
        "Action" : "cloudwatch:PutMetricData",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateRoute",
          "ec2:DeleteRoute"
        ],
        "Resource" : "arn:aws:ec2:*:*:route-table/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateTags"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:security-group-rule/*",
          "arn:aws:ec2:*:*:route-table/*",
          "arn:aws:ec2:*:*:vpc-peering-connection/*",
          "arn:aws:ec2:*:*:vpc/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group-rule/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress"
        ],
        "Resource" : "arn:aws:ec2:*:*:security-group/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:AcceptVpcPeeringConnection",
          "ec2:ModifyVpcPeeringConnectionOptions"
        ],
        "Resource" : "arn:aws:ec2:*:*:vpc-peering-connection/*"
      },
      {
        "Effect" : "Allow",
        "Action" : "ec2:AcceptVpcPeeringConnection",
        "Resource" : "arn:aws:ec2:*:*:vpc/*"
      }


    ]
  })
}

resource "aws_iam_role_policy_attachment" "dms_policy_attachment" {
  role       = aws_iam_role.dms_role.name
  policy_arn = aws_iam_policy.dms_policy.arn
}

resource "aws_iam_role_policy" "secret_access" {
  for_each = var.secrets
  name     = "${var.name}-secret-access-${each.key}"
  role     = aws_iam_role.dms_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = each.value
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "rds_role_policy_attachment" {
  for_each   = var.rds_access_policy_arns
  role       = aws_iam_role.dms_role.name
  policy_arn = each.value
}

