#!/bin/bash

CONFIG_FILE="$HOME/.glacier_cleanup_config"
CLEANUP_SCRIPT="glacier_cleanup.sh"

echo "🔧 AWS Glacier Cleanup Script Installer"
echo "---------------------------------------"

# Function to check for command existence
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1️⃣ Check for AWS CLI
if ! command_exists aws; then
    echo "❌ AWS CLI is NOT installed!"
    echo "ℹ️  AWS CLI is required to interact with AWS Glacier."
    read -p "Do you want to install AWS CLI now? (y/n) " install_aws
    if [[ "$install_aws" =~ ^[Yy]$ ]]; then
        echo "📦 Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    else
        echo "❌ AWS CLI installation skipped. Exiting..."
        exit 1
    fi
fi

# 2️⃣ Check for Homebrew
if ! command_exists brew; then
    echo "❌ Homebrew is NOT installed!"
    echo "ℹ️  Homebrew is required to install dependencies like 'jq'."
    read -p "Do you want to install Homebrew now? (y/n) " install_brew
    if [[ "$install_brew" =~ ^[Yy]$ ]]; then
        echo "📦 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"  # Ensure brew is available
    else
        echo "❌ Homebrew installation skipped. Exiting..."
        exit 1
    fi
fi

# 3️⃣ Check for jq (JSON processor)
if ! command_exists jq; then
    echo "❌ 'jq' is NOT installed!"
    echo "ℹ️  'jq' is required for processing AWS Glacier inventory data."
    read -p "Do you want to install jq using Homebrew? (y/n) " install_jq
    if [[ "$install_jq" =~ ^[Yy]$ ]]; then
        echo "📦 Installing jq..."
        brew install jq
    else
        echo "❌ jq installation skipped. Exiting..."
        exit 1
    fi
fi

# ✅ Display system versions
echo ""
echo "✅ System Check Complete!"
echo "---------------------------------------"
echo "🔹 AWS CLI Version: $(aws --version 2>/dev/null)"
echo "🔹 Homebrew Version: $(brew --version 2>/dev/null | head -n 1)"
echo "🔹 jq Version: $(jq --version 2>/dev/null)"
echo "🔹 Cleanup Script: $CLEANUP_SCRIPT"
echo "---------------------------------------"
echo ""

# 4️⃣ Ask for AWS Account ID
read -p "Enter your AWS Account ID: " ACCOUNT_ID

# Validate input
if [[ -z "$ACCOUNT_ID" ]]; then
    echo "❌ Error: AWS Account ID cannot be empty!"
    exit 1
fi

# Save configuration
echo "ACCOUNT_ID=$ACCOUNT_ID" > "$CONFIG_FILE"
echo "✅ Configuration saved to $CONFIG_FILE"

# Ensure the cleanup script is executable
chmod +x "$CLEANUP_SCRIPT"

# ✅ Display installation success message and usage instructions
echo ""
echo "🎉 Installation complete!"
echo "---------------------------------------"
echo "📌 How to use the script:"
echo "  ➤ Run: ./$CLEANUP_SCRIPT <VAULT_NAME>"
echo "  ➤ Example: ./$CLEANUP_SCRIPT my-glacier-vault"
echo "---------------------------------------"
echo "🚀 You're all set! Happy cleaning! 🎉"

