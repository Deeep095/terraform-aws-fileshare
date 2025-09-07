output "all_outputs" {
  description = "All available outputs. User can select the ones they want."
  value = {
    bucket_name         = aws_s3_bucket.files.bucket
    bucket_arn          = aws_s3_bucket.files.arn
    table_name          = aws_dynamodb_table.files.name
    table_arn           = aws_dynamodb_table.files.arn
    api_invoke_url      = aws_apigatewayv2_api.this.api_endpoint
    routes = {
      upload    = "${aws_apigatewayv2_api.this.api_endpoint}/upload"
      download  = "${aws_apigatewayv2_api.this.api_endpoint}/download"
      multipart = "${aws_apigatewayv2_api.this.api_endpoint}/multipart"
      complete  = "${aws_apigatewayv2_api.this.api_endpoint}/complete"
    }
    cdn_domain          = try(aws_cloudfront_distribution.cdn.domain_name, null)
    cdn_distribution_id = try(aws_cloudfront_distribution.cdn.id, null)
    sns_topic_arn       = aws_sns_topic.upload_notifications.arn
  }
}
