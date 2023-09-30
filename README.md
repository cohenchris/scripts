# scripts for mediaserver

1. Copy sample.env -> env
2. Fill in all fields in env file
3. Set up a cron job to execute music-rating-progress-sheet.py and website-listening-progress-json.py
4. Create 'hatoken' with Home Assistant long-term access token
    Then, set secure access permissions
    ```
    chmod 600 hatoken
    chown root:root hatoken
    ```
