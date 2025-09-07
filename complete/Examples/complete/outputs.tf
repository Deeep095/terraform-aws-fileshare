#########################
# Core resource outputs #
#########################

output "bucket_name" {
  description = "Private S3 bucket used for file storage."
  value       = module.fileshare.bucket_name
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = module.fileshare.bucket_arn
}

output "table_name" {
  description = "DynamoDB table name storing file metadata."
  value       = module.fileshare.table_name
}

output "table_arn" {
  description = "ARN of the DynamoDB table."
  value       = module.fileshare.table_arn
}

#########################
# API Gateway endpoints #
#########################

output "api_invoke_url" {
  description = "Base URL for the HTTP API (invoke URL)."
  value       = module.fileshare.api_invoke_url
}

output "routes" {
  description = "Convenience map of the presign service routes."
  value = module.fileshare.routes
}

#########################
# CDN (optional)        #
#########################

# Use try() to avoid errors if the distribution is not created (count = 0)
output "cdn_domain" {
  description = "CloudFront distribution domain name, if CDN is enabled."
  value       = module.fileshare.cdn_domain
}

output "cdn_distribution_id" {
  description = "CloudFront distribution ID, if CDN is enabled."
  value       = module.fileshare.cdn_distribution_id
}

#########################
# Notifications (SNS)   #
#########################

output "sns_topic_arn" {
  description = "SNS topic ARN used for upload-complete notifications."
  value       = module.fileshare.sns_topic_arn
}
