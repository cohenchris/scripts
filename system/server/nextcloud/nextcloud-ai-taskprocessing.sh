#!/bin/bash
echo "Starting Nextcloud AI Worker $1"

# Function to attempt starting the worker
start_worker() {
    echo "Attempting to start Nextcloud AI Worker $1..."
    
    # Run the worker inside the container (60 seconds for task execution)
    docker exec --user www-data nextcloud php occ background-job:worker -t 60 'OC\TaskProcessing\SynchronousBackgroundJob'
    
    # Capture the exit status of the docker exec command
    exit_code=$?

    # Check if the worker ran successfully
    if [ $exit_code -eq 0 ]; then
        echo "Worker completed successfully."
        return 0  # Success
    else
        echo "Worker failed to start or complete with exit code $exit_code."
        return 1  # Failure
    fi
}

# Loop to start the worker and retry if it fails
while true; do
    # Check if the container is running
    if ! docker ps --format "{{.Names}}" | grep -q "^nextcloud$"; then
        echo "Nextcloud container is not running. Waiting 60 seconds before next attempt."
        sleep 60 # If the container isn't running, wait for 60 seconds
        continue  # Skip to the next iteration
    fi

    # Start the worker
    start_worker

    # Check if the worker succeeded or failed
    if [ $? -eq 1 ]; then
        # If failed, wait 30 seconds (or adjust as needed) to avoid rapid retries
        echo "Worker failed. Waiting 30 seconds before retrying..."
        sleep 30
    fi
done
