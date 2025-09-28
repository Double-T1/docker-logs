# log group
resource "aws_cloudwatch_log_group" "logger" {
  name              = "/ecs/${var.project_full_name}-logger"
  retention_in_days = 0 # 0 means never expire
}

# metric filter


# alarm


# dashboard
