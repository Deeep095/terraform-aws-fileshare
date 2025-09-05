# Create an HTTP API Gateway
resource "aws_apigatewayv2_api" "this" {
  name          = "FileUploadAPI"
  protocol_type = "HTTP"
}

# Lambda integration for the API (AWS_PROXY to our Lambda)
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.presign_lambda.invoke_arn
  integration_method = "POST"                     # API Gateway uses POST to invoke Lambda (for proxy)
  payload_format_version = "2.0"
}

# Define routes for each endpoint and associate with the Lambda integration
resource "aws_apigatewayv2_route" "route_upload" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /upload"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
resource "aws_apigatewayv2_route" "route_download" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /download"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
resource "aws_apigatewayv2_route" "route_multipart" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "GET /multipart"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}
resource "aws_apigatewayv2_route" "route_complete" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /complete"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Deploy the API with a default stage
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true    # changes deploy automatically
}

# Permission for API Gateway to invoke the Lambda
resource "aws_lambda_permission" "allow_apigw_invoke" {
  function_name = aws_lambda_function.presign_lambda.function_name
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*"
}
