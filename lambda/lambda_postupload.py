import os
import json
import boto3
from datetime import datetime

dynamo = boto3.resource('dynamodb')
sns = boto3.client('sns')

TABLE_NAME = os.environ.get('TABLE_NAME')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
table = dynamo.Table(TABLE_NAME)

def lambda_handler(event, context):
    """Triggered by S3 when a file upload completes. Updates DB and sends notification."""
    # The event can contain multiple records (batch). Process each.
    records = event.get("Records", [])
    for record in records:
        try:
            # Only care about ObjectCreated events
            event_name = record.get("eventName", "")
            if not event_name.startswith("ObjectCreated"):
                continue  # ignore other events if any

            bucket = record["s3"]["bucket"]["name"]
            obj = record["s3"]["object"]
            key = obj["key"]                   # S3 object key
            size = obj.get("size", 0)          # object size in bytes
            # Our S3 key is "<file_id>[.ext]". Extract file_id (part before extension)
            file_id = key.split('.')[0]

            # Get the corresponding DB item
            resp = table.get_item(Key={"file_id": file_id})
            item = resp.get("Item")
            if not item:
                print(f"No metadata found for file_id: {file_id}")
                # If no item, skip further processing
                continue

            # Update the item status to COMPLETED
            update_expr = "SET upload_status = :status, completed_at = :time, file_size = :size"
            expr_vals = {
                ":status": "COMPLETED",
                ":time": datetime.utcnow().isoformat(),
                ":size": size
            }
            table.update_item(Key={"file_id": file_id}, UpdateExpression=update_expr, ExpressionAttributeValues=expr_vals)

            # Send an SNS notification email
            filename = item.get("filename", key)
            message = f"Your file '{filename}' has been uploaded to cloud storage (ID: {file_id}). Size: {size} bytes."
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject="File Upload Complete",
                Message= message
            )
            print(f"Notification sent for {file_id}: {filename}")
        except Exception as e:
            print(f"Error processing S3 event for key {record.get('s3',{}).get('object',{}).get('key')}: {e}")
    return {"statusCode": 200}
