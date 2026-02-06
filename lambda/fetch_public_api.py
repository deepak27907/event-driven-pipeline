import json
import urllib.request
import boto3
from datetime import datetime

s3 = boto3.client("s3")

BUCKET_NAME = "public-api-ingestion-bucket-deepak"  # ← change to YOUR bucket name

def lambda_handler(event, context):
    url = "https://api.coingecko.com/api/v3/simple/price?vs_currencies=usd&ids=bitcoin&x_cg_demo_api_key=CG-ommPVs2xa5ZJURQMnmJrDgY1"

    with urllib.request.urlopen(url) as response:
        api_data = json.loads(response.read())

    record = {
        "source": "CoinGecko",
        "asset": "Bitcoin",
        "price_usd": api_data["bitcoin"]["usd"],
        "timestamp": datetime.utcnow().isoformat()
    }

    file_name = f"crypto-data/{record['timestamp']}.json"

    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=file_name,
        Body=json.dumps(record),
        ContentType="application/json"
    )

    return {
        "statusCode": 200,
        "message": "File uploaded to S3",
        "file": file_name
    }
