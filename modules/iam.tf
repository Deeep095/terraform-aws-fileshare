# IAM role for Lambda functions (trust policy for Lambda service)
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "presign_lambda_role" {
  name               = "presignLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role" "postupload_lambda_role" {
  name               = "postUploadLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Attach basic execution policy (for CloudWatch logs) to both roles
resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  for_each = {
    presign  = aws_iam_role.presign_lambda_role.name
    postupload = aws_iam_role.postupload_lambda_role.name
  }
  role       = each.value
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Inline policy for presign Lambda (S3 and DynamoDB access)
resource "aws_iam_role_policy" "presign_policy" {
  name   = "PresignLambdaPolicy"
  role   = aws_iam_role.presign_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:PutItem",               # add new metadata records
          "dynamodb:GetItem",               # read metadata (for download)
          "dynamodb:UpdateItem"            # update metadata if needed
        ],
        Resource = aws_dynamodb_table.files.arn
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:PutObject",                  # needed for presigned PUT upload (permission is tied to signer)
          "s3:GetObject",                  # for presigned download URLs
          "s3:CreateMultipartUpload",
          "s3:UploadPart",
          "s3:CompleteMultipartUpload",
          "s3:AbortMultipartUpload"
        ],
        Resource = "${aws_s3_bucket.files.arn}/*"
      }
    ]
  })
}

# Inline policy for post-upload Lambda (DynamoDB update and SNS publish)
resource "aws_iam_role_policy" "postupload_policy" {
  name   = "PostUploadLambdaPolicy"
  role   = aws_iam_role.postupload_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ],
        Resource = aws_dynamodb_table.files.arn
      },
      {
        Effect   = "Allow",
        Action   = "sns:Publish",
        Resource = aws_sns_topic.upload_notifications.arn
      }
    ]
  })
}
