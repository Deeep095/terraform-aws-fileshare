# S3 bucket to store uploaded files
resource "aws_s3_bucket" "files" {
  bucket        = "my-dropbox-bucket-33224"               # choose a unique name
  force_destroy = true                              # allow auto-destroy for demo (careful in prod!)
  # (Optional) Enable versioning for file history
  # Default encryption (AES-256) for all objects
  
}

resource "aws_s3_bucket_server_side_encryption_configuration" "configur" {
  bucket = aws_s3_bucket.files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
# Block all public access to this bucket for safety
resource "aws_s3_bucket_public_access_block" "files" {
  bucket                  = aws_s3_bucket.files.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Identity to privately access S3
resource "aws_cloudfront_origin_access_identity" "files_oai" {
  comment = "OAI for S3 bucket"
}

# Bucket policy to allow CloudFront OAI to read objects
resource "aws_s3_bucket_policy" "files_policy" {
  bucket = aws_s3_bucket.files.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { AWS = aws_cloudfront_origin_access_identity.files_oai.iam_arn },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.files.arn}/*"
      }
    ]
  })
}
