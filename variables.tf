variable "notify_email" {
  type = string
  description = "Email address to receive upload notifications"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources in"
  default     = "us-east-1"
}