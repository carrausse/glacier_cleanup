#!/bin/bash

# Ensure a vault name is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a vault name."
    echo "Usage: $0 <VAULT_NAME> [CONCURRENT_DELETIONS]"
    exit 1
fi

VAULT_NAME="$1"
ACCOUNT_ID="your_AWS_accountID"
INVENTORY_FILE="${VAULT_NAME}_glacier_inventory.json"
DEFAULT_CONCURRENT_DELETIONS=10  # Default parallel execution
CONCURRENT_DELETIONS=${2:-$DEFAULT_CONCURRENT_DELETIONS}  # Allow user input

# Check if the inventory file exists
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "❌ Error: Inventory file '$INVENTORY_FILE' not found!"
    exit 1
fi

# Generate timestamp for unique log files
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="${VAULT_NAME}_deleted_archives_${TIMESTAMP}.log"
FAILED_LOG_FILE="${VAULT_NAME}_failed_archives_${TIMESTAMP}.log"

# Extract total number of archives
TOTAL_ARCHIVES=$(jq '.ArchiveList | length' "$INVENTORY_FILE")
echo "🚀 Starting deletion of $TOTAL_ARCHIVES archives from vault: $VAULT_NAME"
echo "🔄 Using $CONCURRENT_DELETIONS parallel deletions"
echo "📝 Logs: $LOG_FILE | Failed: $FAILED_LOG_FILE"

# Ensure log files exist
touch "$LOG_FILE" "$FAILED_LOG_FILE"

# Process and delete archives using xargs for parallel execution
jq -r '.ArchiveList[].ArchiveId' "$INVENTORY_FILE" | grep -v '^$' | \
xargs -P "$CONCURRENT_DELETIONS" -I {} bash -c '
    ARCHIVE_ID="$1"

    # Handle archive IDs that start with "-"
    ARCHIVE_ID_ESCAPED="--archive-id=$ARCHIVE_ID"

    echo "🗑️ Deleting archive: $ARCHIVE_ID"
    
    if aws glacier delete-archive --account-id '"$ACCOUNT_ID"' --vault-name '"$VAULT_NAME"' "$ARCHIVE_ID_ESCAPED"; then
        echo "$ARCHIVE_ID" >> '"$LOG_FILE"'
        echo "✅ Successfully deleted: $ARCHIVE_ID"
    else
        echo "$ARCHIVE_ID" >> '"$FAILED_LOG_FILE"'
        echo "⚠️ Failed to delete: $ARCHIVE_ID"
    fi
' _ {}

echo "✅ Deletion process complete!"
echo "📜 Successfully deleted archives: $(wc -l < "$LOG_FILE")"
echo "⚠️ Failed deletions: $(wc -l < "$FAILED_LOG_FILE")"

