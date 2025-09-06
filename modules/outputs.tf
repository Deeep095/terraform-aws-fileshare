#########################
# Core resource outputs #
#########################

output "bucket_name" {
  description = "Private S3 bucket used for file storage."
  value       = aws_s3_bucket.files.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket."
  value       = aws_s3_bucket.files.arn
}

output "table_name" {
  description = "DynamoDB table name storing file metadata."
  value       = aws_dynamodb_table.files.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table."
  value       = aws_dynamodb_table.files.arn
}

#########################
# API Gateway endpoints #
#########################

output "api_invoke_url" {
  description = "Base URL for the HTTP API (invoke URL)."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "routes" {
  description = "Convenience map of the presign service routes."
  value = {
    upload    = "${aws_apigatewayv2_api.this.api_endpoint}/upload"
    download  = "${aws_apigatewayv2_api.this.api_endpoint}/download"
    multipart = "${aws_apigatewayv2_api.this.api_endpoint}/multipart"
    complete  = "${aws_apigatewayv2_api.this.api_endpoint}/complete"
  }
}

#########################
# CDN (optional)        #
#########################

# Use try() to avoid errors if the distribution is not created (count = 0)
output "cdn_domain" {
  description = "CloudFront distribution domain name, if CDN is enabled."
  value       = try(aws_cloudfront_distribution.cdn.domain_name, null)
}

output "cdn_distribution_id" {
  description = "CloudFront distribution ID, if CDN is enabled."
  value       = try(aws_cloudfront_distribution.cdn.id, null)
}

#########################
# Notifications (SNS)   #
#########################

output "sns_topic_arn" {
  description = "SNS topic ARN used for upload-complete notifications."
  value       = aws_sns_topic.upload_notifications.arn
}
