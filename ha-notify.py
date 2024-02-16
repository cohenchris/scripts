#!/bin/python3

import requests
import json
import sys
import os
from dotenv import load_dotenv
from time import sleep

MAX_NOTIFICATION_ATTEMPTS=100

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
for attempt in range(1, MAX_NOTIFICATION_ATTEMPTS + 1):
    try:
        response = requests.post(url, headers=headers, data=json.dumps(payload))
        if response.status_code == 200:
            print('Notification sent successfully!')
            break
        else:
            print("Notification failed, trying again...")
            sleep(5)
    except:
        print("Notification failed, trying again...")
        sleep(5)
