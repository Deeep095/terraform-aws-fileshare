import os
import json
import uuid
import boto3
from datetime import datetime

# Initialize AWS clients outside handler for efficiency
s3_client = boto3.client('s3')
dynamo = boto3.resource('dynamodb')

# Read environment variables for resource names
BUCKET_NAME = os.environ.get('BUCKET_NAME')
TABLE_NAME  = os.environ.get('TABLE_NAME')
table = dynamo.Table(TABLE_NAME)

def lambda_handler(event, context):
    """Main Lambda handler for presigned URL service."""
    try:
        # Determine which path was called (API Gateway HTTP API)
        http_method = event.get("requestContext", {}).get("http", {}).get("method", "")
        path = event.get("requestContext", {}).get("http", {}).get("path", "")
        query = event.get("queryStringParameters") or {}
        body = None
        if event.get("body"):
            # Parse JSON body if present (for POST /complete)
            body = json.loads(event["body"])

        # Route: GET /upload -> generate presigned upload URL
        if http_method == "GET" and path.endswith("/upload"):
            filename = query.get("name") or query.get("filename")
            if not filename:
                return {"statusCode": 400, "body": json.dumps({"error": "Missing file name"})}
            # Generate a unique file ID and S3 object key
            file_id = str(uuid.uuid4())
            # Preserve file extension if present
            if "." in filename:
                ext = filename.split(".")[-1]
            else:
                ext = ""
            s3_key = file_id + ("." + ext if ext else "")
            # Record metadata in DynamoDB (status pending)
            table.put_item(Item={
                "file_id": file_id,
                "filename": filename,
                "s3_key": s3_key,
                "upload_status": "PENDING",
                "created_at": datetime.utcnow().isoformat()
            })
            # Generate a presigned URL for PUT-ing the file
            presigned_url = s3_client.generate_presigned_url(
                ClientMethod='put_object',
                Params={"Bucket": BUCKET_NAME, "Key": s3_key},
                ExpiresIn=3600  # URL valid for 1 hour
            )
            response = {
                "fileId": file_id,
                "uploadURL": presigned_url
            }
            return {"statusCode": 200, "body": json.dumps(response)}

        # Route: GET /download -> generate presigned download URL
        if http_method == "GET" and path.endswith("/download"):
            file_id = query.get("file_id") or query.get("id")
            if not file_id:
                return {"statusCode": 400, "body": json.dumps({"error": "Missing file_id"})}
            # Lookup the file record in DynamoDB to get S3 key
            result = table.get_item(Key={"file_id": file_id})
            item = result.get("Item")
            if not item:
                return {"statusCode": 404, "body": json.dumps({"error": "File not found"})}
            s3_key = item["s3_key"]
            # Generate presigned URL for GET-ing the file
            presigned_url = s3_client.generate_presigned_url(
                ClientMethod='get_object',
                Params={"Bucket": BUCKET_NAME, "Key": s3_key},
                ExpiresIn=3600  # URL valid for 1 hour
            )
            response = {
                "fileId": file_id,
                "downloadURL": presigned_url,
                # Optionally include CloudFront URL
                "cdnURL": f"https://{os.environ.get('CLOUDFRONT_DOMAIN', '')}/{s3_key}" if os.environ.get('CLOUDFRONT_DOMAIN') else None
            }
            return {"statusCode": 200, "body": json.dumps(response)}

        # Route: GET /multipart -> initiate multipart upload
        if http_method == "GET" and path.endswith("/multipart"):
            filename = query.get("name") or query.get("filename")
            parts_str = query.get("parts") or query.get("partCount")
            if not filename or not parts_str:
                return {"statusCode": 400, "body": json.dumps({"error": "Missing name or parts count"})}
            try:
                part_count = int(parts_str)
            except ValueError:
                return {"statusCode": 400, "body": json.dumps({"error": "Invalid parts count"})}
            # Generate unique file ID and S3 key as before
            file_id = str(uuid.uuid4())
            ext = filename.split(".")[-1] if "." in filename else ""
            s3_key = file_id + ("." + ext if ext else "")
            # Create a multipart upload session on S3
            mp_response = s3_client.create_multipart_upload(Bucket=BUCKET_NAME, Key=s3_key)
            upload_id = mp_response["UploadId"]
            # Save metadata with status "MULTIPART" and store upload_id
            table.put_item(Item={
                "file_id": file_id,
                "filename": filename,
                "s3_key": s3_key,
                "upload_status": "MULTIPART_IN_PROGRESS",
                "upload_id": upload_id,
                "created_at": datetime.utcnow().isoformat()
            })
            # Generate presigned URLs for each part upload
            part_urls = []
            for part_num in range(1, part_count + 1):
                url = s3_client.generate_presigned_url(
                    ClientMethod='upload_part',
                    Params={
                        "Bucket": BUCKET_NAME,
                        "Key": s3_key,
                        "UploadId": upload_id,
                        "PartNumber": part_num
                    },
                    ExpiresIn=3600
                )
                part_urls.append({"partNumber": part_num, "url": url})
            response = {
                "fileId": file_id,
                "uploadId": upload_id,
                "urls": part_urls
            }
            return {"statusCode": 200, "body": json.dumps(response)}

        # Route: POST /complete -> complete multipart upload
        if http_method == "POST" and path.endswith("/complete"):
            if not body:
                return {"statusCode": 400, "body": json.dumps({"error": "Missing request body"})}
            file_id = body.get("fileId")
            upload_id = body.get("uploadId")
            parts = body.get("parts")
            if not file_id or not upload_id or not parts:
                return {"statusCode": 400, "body": json.dumps({"error": "fileId, uploadId and parts are required"})}
            # Lookup the record to get S3 key
            result = table.get_item(Key={"file_id": file_id})
            item = result.get("Item")
            if not item or item.get("upload_id") != upload_id:
                return {"statusCode": 404, "body": json.dumps({"error": "Upload session not found"})}
            s3_key = item["s3_key"]
            # Prepare parts info for completion
            # Ensure ETag values are not quoted (remove quotes if present)
            complete_parts = []
            for p in parts:
                etag = p.get("ETag") or p.get("etag")
                part_num = p.get("PartNumber") or p.get("partNumber")
                if not etag or not part_num:
                    return {"statusCode": 400, "body": json.dumps({"error": "Each part must have PartNumber and ETag"})}
                # Strip quotes from ETag if present
                if etag.startswith('"') and etag.endswith('"'):
                    etag = etag[1:-1]
                complete_parts.append({"ETag": etag, "PartNumber": int(part_num)})
            # Complete the multipart upload in S3
            s3_client.complete_multipart_upload(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                UploadId=upload_id,
                MultipartUpload={"Parts": complete_parts}
            )
            # (Do not send notification here; S3 event will trigger the other Lambda)
            return {"statusCode": 200, "body": json.dumps({"message": "Upload completed", "fileId": file_id})}

        # If none of the routes matched:
        return {"statusCode": 404, "body": json.dumps({"error": "Not Found"})}

    except Exception as e:
        print(f"Error in Lambda: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": "Internal Server Error"})}
