# DynamoDB table to track file metadata
resource "aws_dynamodb_table" "files" {
  name         = "uploaded_files"
  billing_mode = "PAY_PER_REQUEST"        # on-demand capacity
  hash_key     = "file_id"

  attribute {
    name = "file_id"
    type = "S"
  }

  tags = {
    Environment = "dev"
    Name        = "DropboxFilesMetadata"
  }
}
