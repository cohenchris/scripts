#!/bin/python3

import requests
import json
import sys
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
url = os.getenv("HA_NOTIFY_WEBHOOK_ENDPOINT")

# Notification configuration
title = sys.argv[1]
message = sys.argv[2]

# Prepare the headers and payload
headers = {
    'Content-Type': 'application/json',
}

payload = {
    'title': title,
    'message': message,
}

# Send the POST request until it succeeds
response = requests.post(url, headers=headers, data=json.dumps(payload))
while True:
    if response.status_code == 200:
        print('Notification sent successfully!')
        break
    else:
        print("Notification failed, trying again...")
