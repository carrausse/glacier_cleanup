# Glacier Cleanup Scripts

Date of initial creation : 01/02/2025
Last update : 04/02/2025
Creator : Alex Carrausse

Purpose: The purpose of these scripts is to help you delete all the files in your AWS Glacier Vault.

Context: I was very disappointed by the poor documentation available on Synology Glacier and also the very basic commands
available from AWS to address the issue of a AWS Glacier Vault holding millions of backup files and pretty much no easy way
to delete the AWS Glacier Vault. Yes, in order to delete a Vault the Vault must be empty an in order for the vault to be empty
you would need to delete the files one by one using this very basic command:

aws glacier delete-archive --account-id your_AWS_account_ID  --vault-name your_vault_name "archive_ID"

Good luck running this one million times so I created these scripts:
Disclaimer : I was helped by ChatGPT to create those scripts. Use at your own risk. However they worked well on my Mac with AWS CLI.

1. check_glacier3.sh
This script will perform a list of all the archive_IDs in the specified vault. You can then use the json file generated in output
to delete all the archvive_IDs listed in the file.
However BEFORE  you can call check_glacier3.sh you must initiate a retrieval job:
aws glacier initiate-job --account-id YOUR_AWS_ACCOUNT_ID  --vault-name YOUR_VAULT_NAME  --job-parameters '{"Type": "inventory-retrieval"}' --region YOUR_AWS_REGION
Once the job is kicked off you can already initiate the check_glacier3.sh script.
The command to launch the script is ./check_glacier3.sh YOUR_VAULT_NAME (don't forget to edit the script and edit your AWS_ACCOUNT_ID which is hardcoded in the script.
Also don't forget to do a chmod +x check_glacier3.sh in order to be able to execute it.
Once the script is running it will periodaclly check if the job is ready every 10 minutes. 
It will run in a loop, just be patient as the job retrieval may take hours if not days.
Once the job is ready you will be prompted and then you can move on to the next step : glacier_cleanup9.sh


2. glacier_cleanup9.sh


3.
