variable "env" {
  description = "The environment name, e.g. dev, staging, prod"
  type        = string
  default     = "dev"
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