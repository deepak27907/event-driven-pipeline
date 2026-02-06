import json
import boto3
from datetime import datetime, timezone

s3 = boto3.client("s3")

BUCKET_NAME = "public-api-ingestion-bucket-deepak"   # 👈 change this
RAW_PREFIX = "crypto-data/"
REPORT_PREFIX = "daily-reports/"

def lambda_handler(event, context):
    today = datetime.now(timezone.utc).date().isoformat()

    # List objects from S3
    response = s3.list_objects_v2(
        Bucket=BUCKET_NAME,
        Prefix=RAW_PREFIX
    )

    prices = []

    if "Contents" not in response:
        return {"message": "No data found"}

    for obj in response["Contents"]:
        obj_key = obj["Key"]
        if obj_key.endswith(".json"):
            file_obj = s3.get_object(Bucket=BUCKET_NAME, Key=obj_key)
            data = json.loads(file_obj["Body"].read())
            prices.append(data["price_usd"])

    if not prices:
        return {"message": "No price data available"}

    report = {
        "date": today,
        "total_records": len(prices),
        "min_price": min(prices),
        "max_price": max(prices),
        "average_price": round(sum(prices) / len(prices), 2)
    }

    report_key = f"{REPORT_PREFIX}summary-{today}.json"

    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=report_key,
        Body=json.dumps(report),
        ContentType="application/json"
    )

    return {
        "status": "success",
        "report_file": report_key,
        "summary": report
    }
