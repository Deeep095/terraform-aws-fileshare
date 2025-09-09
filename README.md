````markdown
# Fileshare (Terraform Module)

A composable Terraform module that creates a **secure private file storage system** using AWS services.  
It provides presigned URLs for uploads and downloads via **API Gateway + Lambda**, stores file metadata in **DynamoDB**, supports **CloudFront CDN integration**, and sends **SNS email notifications** on uploads.  

The S3 bucket remains **fully private** with Block Public Access enabled. Clients never receive AWS credentials — they only interact via short-lived signed URLs.

---

## 🚀 How It Works

- **Upload & Download**  
  API Gateway (HTTP) invokes a Lambda function that generates presigned S3 URLs for PUT/GET (and multipart uploads).  
  File metadata is stored in DynamoDB. S3 validates each presigned request using SigV4 and enforces expiry.

- **Post-Upload Processing**  
  S3 `ObjectCreated` events trigger a Lambda that updates the DynamoDB record to mark the file as `COMPLETED` and publishes an **SNS email notification**.

- **Optional CDN**  
  CloudFront with **Origin Access Control (OAC)** can serve content from the private S3 bucket.  
  This allows global low-latency downloads while keeping the bucket non-public.

---

## 📂 Module Structure

This module follows Terraform best practices, splitting resources across files for clarity and reuse:

- **s3.tf** — Private S3 bucket, SSE, CORS, policy, event bindings.  
- **dynamodb.tf** — `uploaded_files` table (pk: file_id).  
- **sns.tf** — SNS topic + optional email subscription.  
- **lambda_presign.tf** — Lambda for generating presigned URLs.  
- **lambda_postupload.tf** — Lambda for post-upload processing.  
- **apigw.tf** — HTTP API, routes (`/upload`, `/download`, `/multipart`, `/complete`).  
- **cloudfront.tf** — Optional CloudFront distribution with OAC.  
- **policies.tf** — IAM policy documents.  
- **variables.tf, outputs.tf, versions.tf, main.tf** — Inputs, outputs, provider, locals.  

---

## ⚙️ Inputs (Key Variables)

| Name              | Type   | Default             | Description                                     |
|-------------------|--------|---------------------|-------------------------------------------------|
| `aws_region`      | string | `us-east-1`         | AWS region to deploy resources.                 |
| `notify_email`    | string | n/a (required)      | Email for SNS notifications.                    |
| `bucket_prefix`   | string | `bucket-s3-files`   | Prefix for the S3 bucket name.                  |

---

## 📤 Outputs

| Name             | Description                                   |
|------------------|-----------------------------------------------|
| `api_invoke_url` | Base API Gateway invoke URL.                  |
| `routes`         | Map of endpoint routes (`/upload`, etc.).     |
| `bucket_name`    | Name of the private S3 bucket.                |
| `table_name`     | DynamoDB table storing file metadata.         |
| `cdn_domain`     | CloudFront domain (if enabled).               |

---

## 📌 Example Usage

A complete working example is available here:  
[**Complete Example**](https://github.com/Deeep095/terraform-aws-fileshare/tree/main/examples/complete)

###  Example

```hcl
module "fileshare" {
  source  = "Deeep095/fileshare/aws"
  version = "1.1.6"

  notify_email = "test@example.com"

  # Optionally override defaults
  # aws_region   = "ap-south-1"
  # bucket_prefix = "bucket-s3-files-upload"
}
````

---

## 4. Deployment Process

This section explains how to deploy and test the system.

### 4.1 Prerequisites

* **AWS CLI and Credentials**
  Configure AWS credentials (via `aws configure`) with permissions to create:
  S3, DynamoDB, Lambda, API Gateway, CloudFront, SNS, and IAM resources.

* **Terraform**
  Install Terraform and initialize it in your project directory.

---

### 4.3 Terraform Deployment

1. **Configure Variables**
   Set required variables (e.g., `notify_email`) using a `terraform.tfvars` file or environment variables.

2. **Initialize Terraform**

   ```sh
   terraform init
   ```

3. **Review the Plan**

   ```sh
   terraform plan
   ```

   Check the plan output to verify resources and ensure bucket names are unique.

4. **Apply the Configuration**

   ```sh
   terraform apply
   ```

   Type **`yes`** when prompted.
   Resource creation can take several minutes (CloudFront may take longer).

5. **Confirm SNS Subscription**
   After apply, AWS sends a confirmation email to your `notify_email`.
   Click the link to start receiving notifications.

✅ Once `terraform apply` completes and SNS is confirmed, the system is ready.

---

## 5. Testing the API with cURL

After deployment, you can interact with the API using `curl`.
The base URL will be shown in Terraform outputs (e.g., `api_invoke_url`).

### 5.1 Request a Presigned Upload URL

```sh
curl -X POST "${API_URL}/upload?name=photo.jpg"
```

Example Response:

```json
{
  "fileId": "123e4567-e89b-12d3-a456-426614174000",
  "uploadURL": "https://bucket-name.s3.amazonaws.com/...presigned..."
}
```

Save the `fileId` for later.

---

### 5.2 Upload a File to S3

```sh
curl -X PUT -T "photo.jpg" "https://bucket-name.s3.amazonaws.com/...presigned..."
```

* Returns `200` or `204` on success.
* Triggers the PostUpload Lambda → DynamoDB updated → SNS email sent.

---

### 5.3 Download a File

```sh
curl -X GET "${API_URL}/download?fileId=<your-file-id>"
```

Example Response:

```json
{
  "downloadURL": "https://bucket-name.s3.amazonaws.com/...presigned...",
  "cdnURL": "https://d1234abcd.cloudfront.net/photo.jpg"
}
```

Download via presigned URL:

```sh
curl -o photo-downloaded.jpg "https://bucket-name.s3.amazonaws.com/...presigned..."
```

Or via CloudFront (if enabled):

```sh
curl -o photo-downloaded.jpg "https://d1234abcd.cloudfront.net/photo.jpg"
```

---

### 5.4 Multipart Upload (Optional)

For large files:

1. **Request Part URLs**

   ```sh
   curl -X GET "${API_URL}/multipart?name=large.bin&parts=3"
   ```

2. **Upload Each Part**

   ```sh
   curl -X PUT -T "chunk1" "url1"
   curl -X PUT -T "chunk2" "url2"
   curl -X PUT -T "chunk3" "url3"
   ```

3. **Complete Upload**

   ```sh
   curl -X POST "${API_URL}/complete" \
     -H "Content-Type: application/json" \
     -d '{
       "fileId": "uuid",
       "uploadId": "xyz123",
       "parts": [
         {"PartNumber":1,"ETag":"etag1"},
         {"PartNumber":2,"ETag":"etag2"},
         {"PartNumber":3,"ETag":"etag3"}
       ]
     }'
   ```

S3 finalizes the upload, DynamoDB is updated, and SNS sends a notification.

---

## ✅ Summary

This module provides a secure, serverless file-sharing solution on AWS with:

* Private S3 bucket (Block Public Access ON).
* Short-lived presigned URLs for uploads/downloads.
* DynamoDB tracking of file metadata.
* SNS notifications after upload.
* Optional CloudFront CDN distribution.


