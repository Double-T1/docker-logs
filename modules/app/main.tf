# iam
## execution
resource "aws_iam_role" "logger_execution" {
  name = "${var.project_full_name}-logger-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment_name
    Project     = var.project_full_name
  }
}

data "aws_iam_policy_document" "logger_execution" {
  source_policy_documents = [
    templatefile("${path.module}/policies/execution-role-policy.json", {
      project_full_name = var.project_full_name
    })
  ]
}

resource "aws_iam_role_policy" "logger_execution" {
  role   = aws_iam_role.logger_execution.id
  policy = data.aws_iam_policy_document.logger_execution.json
}

## task
resource "aws_iam_role" "logger_task" {
  name = "${var.project_full_name}-logger-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment_name
    Project     = var.project_full_name
  }
}

data "aws_iam_policy_document" "logger_task" {
  source_policy_documents = [
    templatefile("${path.module}/policies/task-role-policy.json", {
      project_full_name = var.project_full_name
    })
  ]
}

resource "aws_iam_role_policy" "logger_task" {
  role   = aws_iam_role.logger_task.id
  policy = data.aws_iam_policy_document.logger_task.json
}

# ecs
## ecs cluster
resource "aws_ecs_service" "logger_service" {
  name                   = "${var.project_full_name}-logger"
  cluster                = var.ecs_cluster
  task_definition        = aws_ecs_task_definition.logger.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = true
  }
}

## ecs task definition
resource "aws_ecs_task_definition" "logger" {
  family                   = "${var.project_full_name}-logger"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.logger_execution.arn
  task_role_arn            = aws_iam_role.logger_task.arn

  container_definitions = templatefile("${path.module}/templates/logger.json", {
    PROJECT_FULL_NAME  = var.project_full_name,
    ENVIRONMENT        = var.environment_name,
    AWS_ACCOUNT_ID     = var.aws_account_id,
  })
}


# ecr
## ecr repository
resource "aws_ecr_repository" "logger" {
  name = "${var.project_full_name}-logger"

  image_scanning_configuration {
    scan_on_push = true # Enable vulnerability scanning
  }
}

## ecr lifecycle policy
resource "aws_ecr_lifecycle_policy" "logger" {
  repository = aws_ecr_repository.logger.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire images older than 14 days",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 14
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Keep last 10 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}
