# Allow S3 to invoke the post-upload Lambda
resource "aws_lambda_permission" "allow_s3_trigger" {
  function_name = aws_lambda_function.postupload_lambda.function_name
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.files.arn           # Only this bucket can trigger
}

# S3 bucket notification to trigger Lambda on new object creation
resource "aws_s3_bucket_notification" "files_notifications" {
  bucket = aws_s3_bucket.files.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.postupload_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""    # (optional filter, e.g., only certain folder)
    filter_suffix       = ""    # (optional filter, e.g., only certain file type)
  }

  depends_on = [aws_lambda_permission.allow_s3_trigger]
}
