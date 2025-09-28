variable "project_full_name" {
  description = "The full project name used for naming resources"
  type        = string
}

variable "environment_name" {
  description = "The environment name (dev, staging, prod)"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
  default     = ""
}

variable "error_threshold" {
  description = "Error threshold for CloudWatch alarms"
  type        = number
  default     = 5
}

variable "warning_threshold" {
  description = "Warning threshold for CloudWatch alarms"
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "Log retention period in days (0 means never expire)"
  type        = number
  default     = 0
}