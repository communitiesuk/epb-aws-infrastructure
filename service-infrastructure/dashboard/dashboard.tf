resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "useful-graphs"

  dashboard_body = jsonencode({
    "widgets" : [
      {
        height : 6,
        width : 12,
        y : 17,
        x : 0,
        type : "metric",
        properties : {
          metrics : [
            [
              "AWS/ECS", "CPUUtilization", "ClusterName", "epb-${var.environment}-frontend-cluster", "ServiceName",
              "epb-${var.environment}-frontend", { stat : "Average", region : var.region }
            ],
            [
              "...", "epb-${var.environment}-toggles-cluster", ".", "epb-${var.environment}-toggles", { stat : "Average", region : var.region }
            ],
            [
              "...", "epb-${var.environment}-reg-sidekiq-cluster", ".", "epb-${var.environment}-reg-sidekiq",
              { stat : "Average", region : var.region }
            ],
            [
              "...", "epb-${var.environment}-reg-api-cluster", ".", "epb-${var.environment}-reg-api", { stat : "Average", region : var.region }
            ],
            [
              "...", "epb-${var.environment}-warehouse-cluster", ".", "epb-${var.environment}-warehouse",
              { stat : "Average", region : var.region }
            ],
            ["...", "epb-${var.environment}-auth-cluster", ".", "epb-${var.environment}-auth", { stat : "Average", region : var.region }]
          ],
          legend : {
            position : "right"
          },
          region : var.region,
          liveData : false,
          timezone : "UTC",
          title : "ECS - CPU Utilization: Average",
          view : "timeSeries",
          stacked : false,
          period : 60
        }
      },
      {
        height : 6,
        width : 12,
        y : 17,
        x : 12,
        type : "metric",
        properties : {
          metrics : [
            [
              "AWS/ECS", "MemoryUtilization", "ClusterName", "epb-${var.environment}-frontend-cluster", "ServiceName",
              "epb-${var.environment}-frontend", { stat : "Average", region : var.region }
            ],
            [
              "...", "epb-${var.environment}-warehouse-cluster", ".", "epb-${var.environment}-warehouse",
              { stat : "Average", region : var.region }
            ],
            [
              "...", "epb-${var.environment}-toggles-cluster", ".", "epb-${var.environment}-toggles", { stat : "Average", region : var.region }
            ],
            ["...", "epb-${var.environment}-auth-cluster", ".", "epb-${var.environment}-auth", { stat : "Average", region : var.region }],
            [
              "...", "epb-${var.environment}-reg-sidekiq-cluster", ".", "epb-${var.environment}-reg-sidekiq",
              { stat : "Average", region : "eu-west-2" }
            ],
            ["...", "epb-${var.environment}-reg-api-cluster", ".", "epb-${var.environment}-reg-api", { stat : "Average", region : var.region }]
          ],
          legend : {
            position : "right"
          },
          region : var.region,
          liveData : false,
          timezone : "UTC",
          title : "ECS - Memory Utilization: Average",
          view : "timeSeries",
          stacked : false,
          period : 60
        }
      },
      {
        height : 6,
        width : 6,
        y : 11,
        x : 6,
        type : "metric",
        properties : {
          metrics : [
            [
              {
                expression : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"RequestCount\" ', 'Sum', 60)",
                region : var.region
              }
            ]
          ],
          legend : {
            position : "bottom"
          },
          title : "ELB - Request Count: Sum",
          region : var.region,
          liveData : false,
          timezone : "UTC",
          view : "timeSeries",
          stacked : false,
          period : 300,
          stat : "Average"
        }
      },
      {
        height : 6,
        width : 12,
        y : 23,
        x : 0,
        type : "metric",
        properties : {
          metrics : [
            [
              "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "epb-${var.environment}-toggles-postgres-db",
              { stat : "Average", region : var.region }
            ],
            ["...", "epb-${var.environment}-auth-postgres-db", { stat : "Average", region : var.region }],
            ["...", "epb-${var.environment}-warehouse-aurora-db-1", { stat : "Average", region : var.region }],
            ["...", "epb-${var.environment}-reg-api-aurora-db-1", { stat : "Average", region : var.region }],
            ["...", "epb-${var.environment}-reg-api-aurora-db-0", { stat : "Average", region : var.region }],
            ["...", "epb-${var.environment}-warehouse-aurora-db-0", { stat : "Average", region : var.region }]
          ],
          legend : {
            position : "right"
          },
          region : var.region,
          liveData : false,
          timezone : "UTC",
          title : "RDS - CPU Utilization: Average",
          view : "timeSeries",
          stacked : false,
          period : 60
        }
      },
      {
        height : 6,
        width : 12,
        y : 23,
        x : 12,
        type : "metric",
        properties : {
          metrics : [
            [
              "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "epb-${var.environment}-reg-api-aurora-db-1",
              { region : var.region }
            ],
            ["...", "epb-${var.environment}-warehouse-aurora-db-1", { region : var.region }],
            ["...", "epb-${var.environment}-auth-postgres-db", { region : var.region }],
            ["...", "epb-${var.environment}-toggles-postgres-db", { region : var.region }],
            ["...", "epb-${var.environment}-warehouse-aurora-db-0", { region : var.region }],
            ["...", "epb-${var.environment}-reg-api-aurora-db-0", { region : var.region }]
          ],
          legend : {
            position : "right"
          },
          region : var.region,
          liveData : false,
          timezone : "UTC",
          title : "RDS - Database Connections: Average",
          view : "timeSeries",
          stacked : false,
          period : 60,
          stat : "Average"
        }
      },
      {
        height : 6,
        width : 6,
        y : 11,
        x : 18,
        type : "metric",
        properties : {
          metrics : [
            [
              "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.albs.auth,
              { region : var.region }
            ],
            [
              "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.albs.auth_internal,
              { region : var.region }
            ],
            [
              "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.albs.frontend,
              { region : var.region }
            ],
            [
              "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.albs.reg_api,
              { region : var.region }
            ],
            [
              "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.albs.reg_api_internal,
              { region : var.region }
            ],
            [
              "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.albs.toggles,
              { region : var.region }
            ],
            [
              "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.albs.toggles_internal,
              { region : var.region }
            ]
          ],
          view : "timeSeries",
          stacked : false,
          region : var.region,
          title : "ELB - Target Response Time",
          period : 60,
          stat : "Average"
        }
      },
      {
        height : 6,
        width : 6,
        y : 5,
        x : 0,
        type : "metric",
        properties : {
          metrics : [
            [
              {
                expression : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_3XX_Count\" ', 'Sum', 60)",
                region : var.region
              }
            ]
          ],
          legend : {
            position : "bottom"
          },
          title : "HTTPCode_ELB_3XX_Count: Sum",
          region : var.region,
          liveData : false,
          timezone : "UTC",
          view : "timeSeries",
          stacked : false,
          period : 60,
          stat : "Average"
        }
      },
      {
        height : 6,
        width : 6,
        y : 5,
        x : 6,
        type : "metric",
        properties : {
          metrics : [
            [
              {
                expression : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_ELB_4XX_Count\" ', 'Sum', 60)",
                region : var.region
              }
            ]
          ],
          legend : {
            position : "bottom"
          },
          title : "HTTPCode_ELB_4XX_Count: Sum",
          region : var.region,
          liveData : false,
          timezone : "UTC",
          view : "timeSeries",
          stacked : false,
          period : 60,
          stat : "Average"
        }
      },
      {
        height : 5,
        width : 12,
        y : 0,
        x : 0,
        type : "metric",
        properties : {
          metrics : [
            [
              "AWS/ECS", "CPUUtilization", "ClusterName", "epb-${var.environment}-frontend-cluster", "ServiceName",
              "epb-${var.environment}-frontend", { region : var.region }
            ],
            ["...", "epb-${var.environment}-toggles-cluster", ".", "epb-${var.environment}-toggles", { region : var.region }],
            ["...", "epb-${var.environment}-reg-sidekiq-cluster", ".", "epb-${var.environment}-reg-sidekiq", { region : var.region }],
            ["...", "epb-${var.environment}-reg-api-cluster", ".", "epb-${var.environment}-reg-api", { region : var.region }],
            ["...", "epb-${var.environment}-warehouse-cluster", ".", "epb-${var.environment}-warehouse", { region : var.region }],
            ["...", "epb-${var.environment}-auth-cluster", ".", "epb-${var.environment}-auth", { region : var.region }]
          ],
          legend : {
            position : "right"
          },
          region : var.region,
          liveData : false,
          timezone : "UTC",
          title : "ECS-Tasks",
          view : "singleValue",
          stacked : false,
          period : 60,
          "start" : "-PT2M",
          stat : "SampleCount",
          "end" : "P0D"
        }
      },
      {
        height : 5,
        width : 12,
        y : 0,
        x : 12,
        type : "metric",
        properties : {
          metrics : [
            [
              "AWS/ECS", "CPUUtilization", "ClusterName", "epb-${var.environment}-frontend-cluster", "ServiceName",
              "epb-${var.environment}-frontend", { region : var.region }
            ],
            ["...", "epb-${var.environment}-toggles-cluster", ".", "epb-${var.environment}-toggles", { region : var.region }],
            ["...", "epb-${var.environment}-reg-sidekiq-cluster", ".", "epb-${var.environment}-reg-sidekiq", { region : var.region }],
            ["...", "epb-${var.environment}-reg-api-cluster", ".", "epb-${var.environment}-reg-api", { region : var.region }],
            ["...", "epb-${var.environment}-warehouse-cluster", ".", "epb-${var.environment}-warehouse", { region : var.region }],
            ["...", "epb-${var.environment}-auth-cluster", ".", "epb-${var.environment}-auth", { region : var.region }]
          ],
          legend : {
            position : "right"
          },
          region : var.region,
          liveData : false,
          timezone : "UTC",
          title : "ECS-Tasks",
          view : "timeSeries",
          stacked : false,
          period : 60,
          stat : "SampleCount",
          yAxis : {
            "left" : {
              "min" : 0
            }
          }
        }
      },
      {
        height : 6,
        width : 6,
        y : 5,
        x : 12,
        "type" : "metric",
        "properties" : {
          "legend" : {
            "position" : "bottom"
          },
          "liveData" : false,
          "metrics" : [
            [{ expression : "SEARCH('{AWS/ApplicationELB,LoadBalancer} MetricName=\"HTTPCode_Target_5XX_Count\" ', 'Sum', 60)", region : var.region }]
          ],
          "period" : 60,
          "region" : var.region,
          "stacked" : false,
          "stat" : "Average",
          "timezone" : "UTC",
          "title" : "HTTPCode_Target_5XX_Count: Sum",
          "view" : "timeSeries"
        }
      },
      {
        height : 6,
        width : 6,
        y : 11,
        x : 12,
        type : "metric",
        properties : {
          metrics : [
            [
              "AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup",
              var.target_groups.reg_api, { region : var.region, yAxis : "left" }
            ],
            ["...", var.target_groups.reg_api_internal, { region : var.region }],
            ["...", var.target_groups.frontend, { region : var.region }]
          ],
          view : "timeSeries",
          stacked : false,
          region : var.region,
          period : 60,
          stat : "Sum"
        }
      },
      {
        height : 6,
        width : 6,
        y : 5,
        x : 18,
        type : "metric",
        properties : {
          metrics : [
            ["AWS/CloudFront", "5xxErrorRate", "Region", "Global", "DistributionId", var.cloudfront_distribution_ids.frontend_0.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.frontend_0.name }],
            ["...", var.cloudfront_distribution_ids.auth.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.auth.name }],
            ["...", var.cloudfront_distribution_ids.frontend_1.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.frontend_1.name }],
            ["...", var.cloudfront_distribution_ids.toggles.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.toggles.name }],
            ["...", var.cloudfront_distribution_ids.reg.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.reg.name }]
          ],
          view : "timeSeries",
          stacked : false,
          region : "us-east-1",
          period : 60,
          stat : "Average",
          title : "Cloudfront 5xx Error Rate (% of all responses)"
        }
      },
      {
        height : 6,
        width : 6,
        y : 11,
        x : 0,
        type : "metric",
        properties : {
          metrics : [
            ["AWS/CloudFront", "Requests", "Region", "Global", "DistributionId", var.cloudfront_distribution_ids.frontend_0.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.frontend_0.name }],
            ["...", var.cloudfront_distribution_ids.auth.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.auth.name }],
            ["...", var.cloudfront_distribution_ids.frontend_1.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.frontend_1.name }],
            ["...", var.cloudfront_distribution_ids.toggles.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.toggles.name }],
            ["...", var.cloudfront_distribution_ids.reg.id, { region : "us-east-1", label : var.cloudfront_distribution_ids.reg.name }]
          ],
          view : "timeSeries",
          stacked : false,
          region : "us-east-1",
          title : "Requests to Cloudfront",
          period : 300,
          stat : "Sum"
        }
      }
    ]
  })
}