import re
import boto3
import os
import requests
import urllib.parse

BUCKET_NAME = 'dalle-preview-images'

def _parse_prompt(raw_prompt):
  return urllib.parse.unquote(raw_prompt).replace('_', ' ')

def _create_response(body, status):
  return {
    'statusCode': status,
    'headers': {
      'Content-Type': 'text/html'
    },
    'isBase64Encoded': False,
    'multiValueHeaders': { 
    },
    'body': body,
  }

def _create_success_response(prompt, url):
  html_page = f'''
<html prefix="og: https://ogp.me/ns#">
<head>
<title>Dalle 2 Preview</title>
<meta property="og:title" content="{prompt}" />
<meta property="og:image" content="{url}" />

<meta name="twitter:title" content="{prompt}">
<meta name="twitter:image" content="{url}">

</head>
<img src="{url}"/>
</html>
'''
  return _create_response(html_page, 200)

def isInS3(s3, prompt):
  try:
    s3.head_object(Bucket=BUCKET_NAME, Key=prompt)
    return True
  except Exception:
    return False

def main(event, context):
  prompt = _parse_prompt(event['pathParameters']['prompt'])

  print(f'Prompt: {prompt}')

  if not re.match('^[a-zA-Z0-9\s]+$', prompt):
    return {
      'statusCode': 301,
      'headers': {
        'Content-Type': 'text/html',
        'Location': '/suspicious_duck',
      },
      'isBase64Encoded': False,
      'multiValueHeaders': { 
      },
    }

  s3 = boto3.client('s3')

  if not isInS3(s3, prompt):
    api_token = os.environ.get('DALLE_API_KEY')
    response = requests.post(
      'https://api.openai.com/v1/images/generations',
      json={
        'prompt': prompt,
        'n': 1,
        'size': '256x256'
      },
      headers={
        'Authorization': f'Bearer {api_token}'
      }
    )

    image_url = response.json()['data'][0]['url']

    response = requests.get(image_url, stream=True)

    s3.upload_fileobj(response.raw, BUCKET_NAME, prompt, { 'ContentType': 'image/jpeg'})

  url = s3.generate_presigned_url(
    'get_object',
    Params={
      'Bucket': BUCKET_NAME,
      'Key': prompt
    },
    ExpiresIn=300,
  )
  return _create_success_response(prompt, url)
