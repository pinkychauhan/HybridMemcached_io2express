from pymemcache.client import base
import urllib.parse
import boto3
import os
import json

print('Loading function')

s3 = boto3.client('s3')

memcached_ip = os.environ['MEMCACHED_IP']
memcached_port = os.environ['MEMCACHED_PORT']
client = base.Client(memcached_ip, memcached_port)

def lambda_handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    try:
        s3_object = s3.get_object(Bucket=bucket, Key=key)
        contents = s3_object['Body'].read()
        client.set(key, contents)
        #client.get('key')
        return {
            'statusCode': 200,
            'body': json.dumps('Data added to memcached!')
        }
    except Exception as e:
        print(e)
        raise e



