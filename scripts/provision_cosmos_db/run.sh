#!/bin/bash

metadata=$(curl -s "http://169.254.169.254/skytap")
control_url=$(echo $metadata | jq -r ".user_data" | jq -r ".control_url")
broadcast_url=$(echo $metadata | jq -r ".configuration_user_data" | jq -r ".lab_access_url")/learning_console/broadcast
participant_id=$(curl -s "$control_url" | jq -r ".id")
db_id="ToDoList-$participant_id-$(openssl rand -hex 4)"
az login --service-principal -u $az_username -p $az_password --tenant $az_tenant --output none

db_url=$(az cosmosdb show -n $db_account_name -g $az_rg -o tsv --query "documentEndpoint")

db_access_key=$(az cosmosdb keys list --name $db_account_name --output tsv \
  --query "primaryMasterKey" --resource-group $az_rg)

az cosmosdb sql database create -n $db_id -a $db_account_name -g $az_rg --output none

az cosmosdb sql container create -n Items -a $db_account_name -g $az_rg \
  -p "/partition" -d $db_id --output none

data=$(cat << JSON
{
  "integration_data": {
    "cosmos_url": "$db_url",
    "cosmos_key": "$db_access_key",
    "cosmos_name": "$db_id"
  }
}
JSON
)

curl -s -X PUT "$control_url" -H "Content-Type: application/json" -d "$data" > /dev/null

data=$(cat << JSON
{"type":"refresh_content_pane"}
JSON
)
curl -s -X POST "$broadcast_url" -H "Content-Type: application/json" -d "$data" > /dev/null
