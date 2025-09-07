# SNS topic for upload notifications
resource "aws_sns_topic" "upload_notifications" {
  name = "file-upload-complete"
}

# Email subscription to the SNS topic
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.upload_notifications.arn
  protocol  = "email"
  endpoint  = var.notify_email   # set this to the user's email address
}


