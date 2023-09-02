#!/bin/python3

import requests
import json
import sys

# Home Assistant configuration
home_assistant_url = "https://homeassistant.chriscohen.dev"
device_id = "chris"
hatoken_path="/home/phrog/scripts/hatoken"

try:
    with open(hatoken_path, 'r') as file:
        access_token = file.read().rstrip()

except FileNotFoundError:
    print(f"The file '{file_path}' was not found.")
except Exception as e:
    print(f"An error occurred: {e}")

# Notification configuration
title = "Server Status"
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
