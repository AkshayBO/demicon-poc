import json
import boto3
import os

s3 = boto3.client('s3')

bucket_name=os.environ["bucket_name"]
file=os.environ["file_name"]
resource=os.environ["resource_name"]

def lambda_handler(event, context):
    try:
      bucket = bucket_name
      key = file
      response = s3.get_object(Bucket=bucket, Key=key)
      content = response['Body']
      jsonObject = json.loads(content.read())
      jsonObject= jsonObject['outputs'][resource]['value']
      return jsonObject
    except Exception as err:
        print(err)
