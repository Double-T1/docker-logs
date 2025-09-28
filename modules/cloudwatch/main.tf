# log group
resource "aws_cloudwatch_log_group" "logger" {
  name              = "/ecs/${var.project_full_name}-logger"
  retention_in_days = var.log_retention_days
}

# metric filters
resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "${var.project_full_name}-error-filter"
  log_group_name = aws_cloudwatch_log_group.logger.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "${var.project_full_name}-error-count"
    namespace = "ECS/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warn_filter" {
  name           = "${var.project_full_name}-warn-filter"
  log_group_name = aws_cloudwatch_log_group.logger.name
  pattern        = "[timestamp, request_id, level=\"WARN\", ...]"

  metric_transformation {
    name      = "${var.project_full_name}-warn-count"
    namespace = "ECS/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "fatal_filter" {
  name           = "${var.project_full_name}-fatal-filter"
  log_group_name = aws_cloudwatch_log_group.logger.name
  pattern        = "[timestamp, request_id, level=\"FATAL\", ...]"

  metric_transformation {
    name      = "${var.project_full_name}-fatal-count"
    namespace = "ECS/Logs"
    value     = "1"
  }
}

# alarms
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.project_full_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "${var.project_full_name}-error-count"
  namespace           = "ECS/Logs"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_description   = "This metric monitors error rate"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = {
    Environment = var.environment_name
    Project     = var.project_full_name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_warning_rate" {
  alarm_name          = "${var.project_full_name}-high-warning-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "${var.project_full_name}-warn-count"
  namespace           = "ECS/Logs"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.warning_threshold
  alarm_description   = "This metric monitors warning rate"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = {
    Environment = var.environment_name
    Project     = var.project_full_name
  }
}

resource "aws_cloudwatch_metric_alarm" "fatal_errors" {
  alarm_name          = "${var.project_full_name}-fatal-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "${var.project_full_name}-fatal-count"
  namespace           = "ECS/Logs"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors fatal errors"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  treat_missing_data  = "notBreaching"

  tags = {
    Environment = var.environment_name
    Project     = var.project_full_name
  }
}

# dashboard
resource "aws_cloudwatch_dashboard" "logger_dashboard" {
  dashboard_name = "${var.project_full_name}-logger-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["ECS/Logs", "${var.project_full_name}-error-count"],
            [".", "${var.project_full_name}-warn-count"],
            [".", "${var.project_full_name}-fatal-count"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "ap-southeast-1"
          title   = "Log Levels Over Time"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["ECS/Logs", "${var.project_full_name}-error-count"]
          ]
          view    = "singleValue"
          region  = "ap-southeast-1"
          title   = "Total Errors (24h)"
          period  = 86400
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 6
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["ECS/Logs", "${var.project_full_name}-warn-count"]
          ]
          view    = "singleValue"
          region  = "ap-southeast-1"
          title   = "Total Warnings (24h)"
          period  = 86400
          stat    = "Sum"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          query   = "SOURCE '/ecs/${var.project_full_name}-logger'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20"
          region  = "ap-southeast-1"
          title   = "Recent Error Logs"
        }
      }
    ]
  })
}
