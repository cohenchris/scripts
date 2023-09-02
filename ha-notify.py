#!/bin/python3

import requests
import json
import sys

# Home Assistant configuration
home_assistant_url = "https://homeassistant.chriscohen.dev"
access_token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI4YjQwNzJlYjNmNDA0NTkwODlkMzU1ZDA4YWUwMWVmNyIsImlhdCI6MTY4Njc5MDUwMywiZXhwIjoyMDAyMTUwNTAzfQ.eJQmBjQ0l9sXGM1OalEZyau7xl7iQQnQO824VbRjHEI"
device_id = "chris"

# Notification configuration
title = "Phrog Status"
message = sys.argv[1]
category = "my_category"

# Prepare the API endpoint URL
url = f'{home_assistant_url}/api/services/notify/mobile_app_{device_id}'

# Prepare the headers and payload
headers = {
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {access_token}'
}

payload = {
    'title': title,
    'message': message,
    'data': {
        'push': {
            'category': category
        }
    }
}

# Send the POST request until it succeeds
while True:
    response = requests.post(url, headers=headers, data=json.dumps(payload))
    if response.status_code == 200:
        print('Notification sent successfully!')
        break
