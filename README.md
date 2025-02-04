# Glacier Cleanup Scripts

Date of initial creation : 01/02/2025
Last update : 04/02/2025
Creator : Alex Carrausse

Purpose: The purpose of these scripts is to help you delete all the files in your AWS Glacier Vault.

Context: I was very disappointed by the poor documentation available on Synology Glacier and also the very basic commands
available from AWS to address the issue of a AWS Glacier Vault holding millions of backup files and pretty much no easy way
to delete the AWS Glacier Vault. Yes in order to delete a Vault the Vault must be empty an in order for the vault to be empty
you would need to delete the files one by one using this very basic command:

aws glacier delete-archive --account-id your_AES_acocount_ID  --vault-name your_vault_name "archive_ID"

Good luck running this one million times so I created these scripts:

1. 
