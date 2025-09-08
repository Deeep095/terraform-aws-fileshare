# Package the Lambda code (assumes code is in local files lambda_presign.py and lambda_postupload.py)

data "archive_file" "presign_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_presign.py"
  output_path = "${path.module}/lambda/lambda_presign.zip"
}
data "archive_file" "postupload_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_postupload.py"
  output_path = "${path.module}/lambda/lambda_postupload.zip"
}

resource "aws_lambda_function" "presign_lambda" {
  function_name    = "PresignURLFunction"
  role             = aws_iam_role.presign_lambda_role.arn
  runtime          = "python3.10"
  handler          = "lambda_presign.lambda_handler" # file name and handler function
  filename         = data.archive_file.presign_zip.output_path
  source_code_hash = data.archive_file.presign_zip.output_base64sha256
  timeout          = 15
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.files.bucket,
      TABLE_NAME  = aws_dynamodb_table.files.name
      # (We could also include CloudFront URL or other config if needed)
    }
  }
}

resource "aws_lambda_function" "postupload_lambda" {
  function_name    = "PostUploadFunction"
  role             = aws_iam_role.postupload_lambda_role.arn
  runtime          = "python3.10"
  handler          = "lambda_postupload.lambda_handler"
  filename         = data.archive_file.postupload_zip.output_path
  source_code_hash = data.archive_file.postupload_zip.output_base64sha256

  timeout          = 15
  environment {
    variables = {
      TABLE_NAME    = aws_dynamodb_table.files.name,
      SNS_TOPIC_ARN = aws_sns_topic.upload_notifications.arn
    }
  }
}
