# =============================================================================
# CloudWatch Monitoring - Alerts & Observability
# =============================================================================
#
# WHAT IS CLOUDWATCH?
# CloudWatch is AWS's monitoring service. It collects metrics from your
# services and can alert you when something goes wrong.
#
# LEARNING: App Runner automatically sends metrics to CloudWatch, including:
#   - Request count
#   - Response latency (p50, p90, p99)
#   - Error rates (4xx, 5xx)
#   - Active instances
# =============================================================================

# -----------------------------------------------------------------------------
# SNS Topic for Alerts
# LEARNING: SNS (Simple Notification Service) sends notifications
# You can subscribe email, SMS, Slack webhooks, etc.
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# LEARNING: Subscribe your email to receive alerts
# After applying, you'll get an email to confirm the subscription
resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# -----------------------------------------------------------------------------
# CloudWatch Alarm: High Error Rate
# LEARNING: Triggers when 5xx errors exceed 5% of requests
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "api_errors" {
  alarm_name          = "${var.project_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 5  # 5% error rate
  alarm_description   = "API is returning too many 5xx errors"
  
  # LEARNING: metric_query allows complex math on metrics
  metric_query {
    id          = "error_rate"
    expression  = "(errors / requests) * 100"
    label       = "Error Rate %"
    return_data = true
  }
  
  metric_query {
    id = "errors"
    metric {
      metric_name = "5xxCount"
      namespace   = "AWS/AppRunner"
      period      = 300  # 5 minutes
      stat        = "Sum"
      dimensions = {
        ServiceName = "${var.project_name}-api"
      }
    }
  }
  
  metric_query {
    id = "requests"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/AppRunner"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ServiceName = "${var.project_name}-api"
      }
    }
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Alarm: High Latency
# LEARNING: Triggers when p95 latency exceeds 10 seconds
# For a chatbot waiting on LLM, this is a reasonable threshold
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.project_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RequestLatency"
  namespace           = "AWS/AppRunner"
  period              = 300
  extended_statistic  = "p95"  # Use extended_statistic for percentiles
  threshold           = 10000  # 10 seconds in milliseconds
  alarm_description   = "API response time is too slow (p95 > 10s)"
  
  dimensions = {
    ServiceName = "${var.project_name}-api"
  }
  
  alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Outputs for monitoring URLs
# -----------------------------------------------------------------------------
output "cloudwatch_dashboard_url" {
  description = "Direct link to CloudWatch metrics for your API"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#metricsV2:graph=~();query=~'*7bAWS*2fAppRunner*2cServiceName*7d*20${var.project_name}-api"
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts (subscribe your email/Slack)"
  value       = aws_sns_topic.alerts.arn
}
