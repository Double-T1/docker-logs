# Data sources for networking
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_full_name}-ecs-tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Environment = var.environment_name
    Project     = var.project_full_name
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster

  configuration {
    execute_command_configuration {
      logging    = "OVERRIDE"
      log_driver = "awslogs"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/cluster/${var.ecs_cluster}"
      }
    }
  }

  tags = {
    Environment = var.environment_name
    Project     = var.project_full_name
  }
}

# CloudWatch Log Group for ECS Cluster
resource "aws_cloudwatch_log_group" "ecs_cluster" {
  name              = "/aws/ecs/cluster/${var.ecs_cluster}"
  retention_in_days = 7

  tags = {
    Environment = var.environment_name
    Project     = var.project_full_name
  }
}

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
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.logger.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = length(var.subnets) > 0 ? var.subnets : data.aws_subnets.default.ids
    security_groups  = length(var.security_groups) > 0 ? var.security_groups : [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_cluster.main]
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
    PROJECT_FULL_NAME = var.project_full_name,
    ENVIRONMENT       = var.environment_name,
    AWS_ACCOUNT_ID    = var.aws_account_id,
    AWS_REGION        = var.aws_region
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
