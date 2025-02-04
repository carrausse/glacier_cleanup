#!/bin/bash

# Ensure a vault name is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a vault name."
    echo "Usage: $0 <vault-name>"
    exit 1
fi

VAULT_NAME="$1"
ACCOUNT_ID="998818595369"
CHECK_INTERVAL=600  # 600 seconds = 10 minutes
INVENTORY_FILE="${VAULT_NAME}_glacier_inventory.json"

echo "🚀 Starting Glacier job monitoring script..."
echo "📌 Checking job status every 10 minutes..."
echo "📂 Vault: $VAULT_NAME"

while true; do
    # Get the list of jobs and filter for the latest inventory-retrieval job
    JOB_DATA=$(aws glacier list-jobs --account-id "$ACCOUNT_ID" --vault-name "$VAULT_NAME" --query 'JobList[?Action==`InventoryRetrieval`]|[0]' --output json)

    # Extract Job ID and Status
    JOB_ID=$(echo "$JOB_DATA" | jq -r '.JobId')
    STATUS=$(echo "$JOB_DATA" | jq -r '.StatusCode')

    # If no active job exists, initiate a new job
    if [[ "$JOB_ID" == "null" || -z "$JOB_ID" ]]; then
        echo "🛠️ No active inventory retrieval job found. Initiating a new job..."
        INITIATE_JOB_OUTPUT=$(aws glacier initiate-job --account-id "$ACCOUNT_ID" --vault-name "$VAULT_NAME" --job-parameters '{"Type": "inventory-retrieval"}')

        # Extract new Job ID
        JOB_ID=$(echo "$INITIATE_JOB_OUTPUT" | jq -r '.jobId')
        echo "🚀 New job initiated with Job ID: $JOB_ID"
        echo "⏳ Glacier inventory retrieval can take 4-5 hours..."
    else
        echo "🔍 Found active Job ID: $JOB_ID"
        echo "📊 Current Status: $STATUS"
    fi

    # Check if the job is completed
    if [[ "$STATUS" == "Succeeded" ]]; then
        echo "✅ Job is complete! Downloading inventory..."

        # Get the job output and save it
        aws glacier get-job-output --account-id "$ACCOUNT_ID" --vault-name "$VAULT_NAME" --job-id "$JOB_ID" "$INVENTORY_FILE"

        echo "📂 Inventory saved as $INVENTORY_FILE"
        exit 0
    else
        echo "⏳ Job still in progress. Checking again in 10 minutes..."
    fi

    # Wait before checking again
    sleep "$CHECK_INTERVAL"
done

