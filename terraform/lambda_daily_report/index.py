import boto3
import datetime

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    # This should fetch and process data from the last day
    report_content = "Sample daily report content..."
    key = f"reports/{datetime.datetime.utcnow().date()}.txt"
    s3.put_object(
        Bucket="event-pipeline-report-bucket",
        Key=key,
        Body=report_content
    )
    return {"statusCode": 200, "body": "Report generated"}
