# Dropbox‑style S3 (Terraform Module)

A composable Terraform module that creates a private S3 file store using presigned URLs, API Gateway + Lambda, DynamoDB metadata, optional CloudFront OAC, and SNS email notifications. S3 Block Public Access stays ON; clients never receive AWS credentials and interact via short‑lived signed URLs. This layout follows Terraform’s standard module structure, with resources split across multiple files for clarity and reuse.  

## How it works
- API Gateway (HTTP) invokes a Lambda that generates presigned S3 URLs for PUT/GET (and multipart), and writes/reads file metadata in DynamoDB. S3 validates each presigned request with SigV4 and enforces its expiry, so the bucket can remain fully private under Block Public Access.  
- S3 ObjectCreated events trigger a post‑upload Lambda that marks the file “COMPLETED” in DynamoDB and publishes an SNS email notification.  
- Optional CloudFront with Origin Access Control (OAC) reads from the private bucket; users can fetch via the CDN while S3 remains non‑public.  

References: standard module structure and examples; S3 Block Public Access; presigned URL flows; CloudFront OAC for private S3 origins.  

## Module structure (split files)
- s3.tf: Private bucket, SSE, CORS, policy (and event notification binding).  
- dynamodb.tf: uploaded_files table (pk: file_id).  
- sns.tf: Topic + optional email subscription.  
- lambda_presign.tf: Presign Lambda (BUCKET_NAME, TABLE_NAME, CLOUDFRONT_DOMAIN, URL_EXPIRY_SECONDS).  
- lambda_postupload.tf: Post‑upload Lambda (TABLE_NAME, SNS_TOPIC_ARN).  
- apigw.tf: HTTP API, routes (/upload, /download, /multipart, /complete), integrations.  
- cloudfront.tf: CDN with OAC (preferred) or OAI, bucket policy binding (optional).  
- policies.tf: Shared IAM policy documents.  
- variables.tf, outputs.tf, versions.tf, main.tf: Inputs/outputs/provider/locals.  

This layout follows official guidance for clear module structure and documentation.  

## Inputs (key)
- region  (optional) - string – AWS region. 
- notification_email – string - SNS email subscription.  

## Outputs (key)
- api_invoke_url – Base invoke URL.  
- routes – Map with /upload, /download, /multipart, /complete URLs.  
- bucket_name – S3 bucket.  
- table_name – DynamoDB table.  
- cdn_domain – CloudFront domain (if enabled).  

## Examples

The following examples are available in this repository:

- [Complete Example](https://github.com/Deeep095/terraform-aws-fileshare/tree/main/examples/complete)

### Complete Example

```hcl
module "fileshare" {
  source  = "Deeep095/fileshare/aws"
  version = "1.1.6"

  notify_email = "test@example.com"

  # Optionally override defaults
  # aws_region = "ap-south-1"
  # bucket_name = "bucket-s3-files-upload-54946"
}

