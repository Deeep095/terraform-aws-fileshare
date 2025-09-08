variable "notify_email" {
  type = string
  description = "Email address to receive upload notifications"
  validation {
    condition = can(regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", var.notify_email))
    error_message = "The notify_email must be a valid email address."
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources in"
  default     = "us-east-1"
  validation {
    condition     = contains([
      "us-east-1", "us-west-1", "us-west-2", 
      "eu-west-1", "eu-central-1", "ap-south-1",
      "ap-southeast-1", "ap-southeast-2", "ap-northeast-1",
      "sa-east-1", "ca-central-1", "af-south-1"
    ], var.aws_region)
    error_message = "The aws_region must be a valid AWS region."
  }
}

variable "bucket_prefix" {
  type        = string
  description = "Prefix for the S3 bucket name"
  default     = "bucket-s3-files"
}