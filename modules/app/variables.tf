variable "env" {
  description = "The environment name, e.g. dev, staging, prod"
  type        = string
  default     = "dev"
}

variable "project_full_name" {
  description = "The full project name used for naming resources"
  type        = string
}

variable "environment_name" {
  description = "The environment name (dev, staging, prod)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID for ECR repository URLs"
  type        = string
}

variable "ecs_cluster" {
  description = "ECS cluster name or ARN where the service will be deployed"
  type        = string
}

variable "subnets" {
  description = "subnets for ecs tasks"
  type        = list(string)
  default     = []
}

variable "security_groups" {
  description = "sgs for ecs tasks"
  type        = list(string)
  default     = []
}