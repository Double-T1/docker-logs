output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.logger.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.logger.arn
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-1#dashboards:name=${aws_cloudwatch_dashboard.logger_dashboard.dashboard_name}"
}

output "error_alarm_arn" {
  description = "ARN of the error rate alarm"
  value       = aws_cloudwatch_metric_alarm.high_error_rate.arn
}

output "warning_alarm_arn" {
  description = "ARN of the warning rate alarm"
  value       = aws_cloudwatch_metric_alarm.high_warning_rate.arn
}

output "fatal_alarm_arn" {
  description = "ARN of the fatal error alarm"
  value       = aws_cloudwatch_metric_alarm.fatal_errors.arn
}