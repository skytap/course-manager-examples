# Course Manager Provision CosmosDB Script

## How this script works

This script uses the Azure CLI to provision a database in Azure CosmosDB and then publishes the credentials to Custom Data fields in Course Manager.

## Getting started

### Configure the Custom Data fields


### Prepare the Lab Template

  - Import the shared Script Host template to your account.
  - Create a new environment from this template
  - Add your Azure credentials to the script host VM metadata [(instructions here)](https://help.skytap.com/accessing-vm-metadata-service-from-within-a-vm.html#EditingVMuserdata) as follows:
    ```
    {
      "env": {
        "az_username": "YOUR_AZURE_API_USERNAME_HERE",
        "az_password": "YOUR_AZURE_API_PASSWORD_HERE",
	"az_tenant": "YOUR_AZURE_TENANT_HERE",
	"az_rg": "YOUR_AZURE_RESOURCE_GROUP_HERE",
	"db_account_name": "YOUR_AZURE_COSMOSDB_ACCOUNT_NAME"
      }
    }
    ```
  - Save the environment as a new template
  - Copy the new template to any additional regions
  - Add the script host VM to your training lab templates

### Set up Course Manager

  - Download the script archive [here](../provision_cosmos_db.zip)
  - Log into Course Manager as an admin user
  - Create Custom Data fields to store the CosmosDB credentials generated
    - Browse to Admin -> Settings
    - Find the Custom Data settings under Labs > Integrations
    - Add 3 new Custom Data fields, specifying "cosmos_url", "cosmos_key", and "cosmos_name" respectively for both Attribute key and Label (all other fields can be left as defaults)
  - Enable scripts
    - Browse to Admin -> Settings
    - Find the Scripts settings under General -> Scripts
    - Set "Enable Scripts" to "Yes"
    - Set "Script Host VM Name" to "Script Host"
  - Create a lab course
    - Add the templates you created earlier
    - Click "Course Actions", then "Scripts"
    - Upload the script you downloaded earlier
    - Click "Course Actions", then "Lifecycle Scripts"
    - Under "Provision script", set the following settings:
      - Enable provision script: "Yes"
      - Script name: "provision_cosmos_db.zip"
      - VMs to start before running the script: "Start only the Script Host VM"
      - Failure behavior: "Do not compplete subsequent provision steps"
      - Timeout (seconds): 600
    - Create the manual
      - Click "Course Actions", then "Manual", then "Edit"
      - Click the Insert Placeholders icon (plus sign) and select "Integration Data: cosmos_url" to insert a placeholder for the CosmosDB URL into the manual. This will be replaced with the URL of the CosmosDB database that will be provisioned for each student. Repeat the process for "cosmos_key" and "cosmos_name" as well.
      - Click "Publish" to save and publish the manual.
- Test the script
  - Create a new lab from the course
  - Wait for the provision to finish
  - Access the lab and confirm that the CosmosDB credentials are visible in the manual. This may take several minutes beyond the lab's normal boot time.

## License 

Copyright 2022 Skytap Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
