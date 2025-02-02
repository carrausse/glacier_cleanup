#!/bin/bash

# Ensure a vault name is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a vault name."
    echo "Usage: $0 <VAULT_NAME>"
    exit 1
fi

VAULT_NAME="$1"
ACCOUNT_ID="998818595369"
CHECK_INTERVAL=600  # 600 seconds = 10 minutes
INVENTORY_FILE="${VAULT_NAME}_glacier_inventory.json"

# Generate timestamp for unique log files
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${VAULT_NAME}_deleted_archives_${TIMESTAMP}.log"
FAILED_LOG_FILE="${VAULT_NAME}_failed_archives_${TIMESTAMP}.log"
RETRY_LIMIT=5  # Increase retry limit
DELETE_RATE=10  # Default parallel deletions

echo "🚀 Starting AWS Glacier Cleanup Script"
echo "📂 Vault: $VAULT_NAME"
echo "📌 Checking job status every 10 minutes..."

# Step 1: Check for an active inventory retrieval job
while true; do
    JOB_DATA=$(aws glacier list-jobs --account-id "$ACCOUNT_ID" --vault-name "$VAULT_NAME" --query 'JobList[?Action==`InventoryRetrieval`]|[0]' --output json)
    
    JOB_ID=$(echo "$JOB_DATA" | jq -r '.JobId')
    STATUS=$(echo "$JOB_DATA" | jq -r '.StatusCode')

    if [[ "$JOB_ID" == "null" || -z "$JOB_ID" ]]; then
        echo "🛠️ No active inventory retrieval job found. Initiating a new job..."
        INITIATE_JOB_OUTPUT=$(aws glacier initiate-job --account-id "$ACCOUNT_ID" --vault-name "$VAULT_NAME" --job-parameters '{"Type": "inventory-retrieval"}')

        JOB_ID=$(echo "$INITIATE_JOB_OUTPUT" | jq -r '.jobId')
        echo "🚀 New job initiated with Job ID: $JOB_ID"
        echo "⏳ Glacier inventory retrieval can take 4-5 hours..."
    else
        echo "🔍 Found active Job ID: $JOB_ID"
        echo "📊 Current Status: $STATUS"
    fi

    if [[ "$STATUS" == "Succeeded" ]]; then
        echo "✅ Job is complete! Downloading inventory..."
        aws glacier get-job-output --account-id "$ACCOUNT_ID" --vault-name "$VAULT_NAME" --job-id "$JOB_ID" "$INVENTORY_FILE"
        echo "📂 Inventory saved as $INVENTORY_FILE"
        break
    else
        echo "⏳ Job still in progress. Checking again in 10 minutes..."
        sleep "$CHECK_INTERVAL"
    fi
done

# Step 2: Count total archives in inventory
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "❌ Error: Inventory file '$INVENTORY_FILE' not found!"
    exit 1
fi

TOTAL_ARCHIVES=$(jq '.ArchiveList | length' "$INVENTORY_FILE")
echo "🔢 Total archives ready for deletion: $TOTAL_ARCHIVES"

# Step 3: Ask for confirmation before proceeding
read -p "⚠️ Are you sure you want to delete ALL ($TOTAL_ARCHIVES) archives? (yes/no): " CONFIRMATION
if [[ "$CONFIRMATION" != "yes" ]]; then
    echo "❌ Deletion process canceled."
    exit 1
fi

# Step 4: Ask for deletion rate
read -p "🚀 Enter deletion rate (number of parallel deletions at a time, default 10): " USER_DELETE_RATE
if [[ -n "$USER_DELETE_RATE" && "$USER_DELETE_RATE" -gt 0 ]]; then
    DELETE_RATE=$USER_DELETE_RATE
fi

echo "🔄 Starting parallel deletion of archives with rate: $DELETE_RATE"
echo "📝 Logs: $LOG_FILE | Failed: $FAILED_LOG_FILE"

# Step 5: Process and delete archives
jq -r '.ArchiveList[].ArchiveId' "$INVENTORY_FILE" | grep -v '^$' | \
xargs -P "$DELETE_RATE" -n 1 bash -c '
    ARCHIVE_ID="$1"
    if [[ -z "$ARCHIVE_ID" ]]; then
        echo "❌ Skipping empty archive ID"
        exit 1
    fi

    ATTEMPT=1
    while [[ $ATTEMPT -le '"$RETRY_LIMIT"' ]]; do
        echo "🗑️ [Attempt $ATTEMPT] Deleting archive: $ARCHIVE_ID"

        OUTPUT=$(aws glacier delete-archive --account-id '"$ACCOUNT_ID"' --vault-name '"$VAULT_NAME"' --archive-id "$ARCHIVE_ID" 2>&1)
        EXIT_CODE=$?

        if [[ $EXIT_CODE -eq 0 ]]; then
            echo "$ARCHIVE_ID" >> '"$LOG_FILE"'
            echo "✅ Successfully deleted: $ARCHIVE_ID"
            break
        else
            echo "⚠️ Failed to delete: $ARCHIVE_ID (Attempt $ATTEMPT)" >> '"$FAILED_LOG_FILE"'
            echo "🛑 AWS CLI Error: $OUTPUT" >> '"$FAILED_LOG_FILE"'
            
            ((ATTEMPT++))
            RANDOM_SLEEP=$((RANDOM % 3 + 1))  # Random sleep between 1-3 sec
            sleep $RANDOM_SLEEP
        fi
    done
' _

# Step 6: Summary of deletion results
SUCCESS_COUNT=$(wc -l < "$LOG_FILE" | tr -d ' ')
FAILED_COUNT=$(wc -l < "$FAILED_LOG_FILE" | tr -d ' ')

echo "✅ Deletion process complete!"
echo "✔️ Successfully deleted: $SUCCESS_COUNT archives"
echo "❌ Failed deletions: $FAILED_COUNT archives"
echo "📜 Logs: $LOG_FILE | Failed: $FAILED_LOG_FILE"

