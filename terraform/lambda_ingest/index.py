import json
import boto3
import datetime

s3 = boto3.client('s3')
def lambda_handler(event, context):
    data = {
        "timestamp": str(datetime.datetime.utcnow()),
        "value": "sample event data"
    }
    s3.put_object(
        Bucket="event-pipeline-raw-data",
        Key=f"data/{datetime.datetime.utcnow().isoformat()}.json",
        Body=json.dumps(data)
    )
    return {"statusCode": 200, "body": "Data stored."}
