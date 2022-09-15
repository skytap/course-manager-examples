# Course Manager tunnel script

## How this script works

This script uses the Skytap API to create a network tunnel between the Course Manager lab environment and a shared environment in the same region.

To authenticate to Skytap, the script uses credentials stored in the script host [VM metadata](https://help.skytap.com/accessing-vm-metadata-service-from-within-a-vm.html#EditingVMuserdata)

To identify the target environment, the script uses a [tag set on the source template](https://help.skytap.com/adding-tags-to-templates.html#adding-and-removing-tags-for-templates).

## Getting started

### Create the service user

  - Log into Skytap as an admin user
  - Create a new Skytap user with user type 'restricted'
  - Create a Skytap project for your shared environments
  - Add the new service account to the shared environment project with role 'editor'
  - Add the new service account to the project containing your Course Manager lab environments (usually called 'Course Manager Resources') with role 'editor'
  - Log in as the new user and create an API token. Note the username and token for use later
  
### Prepare your shared environments (one per region)

  - Ensure network is visible to other environments
  - Enable NAT for connected networks on the target environment
  - Ensure that no overlap will occur between the source network, target network, and NAT range
  - More information about network routing between environments [available here](https://help.skytap.com/connecting-multiple-environments.html)

### Prepare your lab templates

  - Import the shared Script Host v9 template to your account. If you do not yet have access to this template, ask your Skytap relationship manager for help.
  - Create a new environment from this template
  - Add the following to the script host VM metadata [(instructions here)](https://help.skytap.com/accessing-vm-metadata-service-from-within-a-vm.html#EditingVMuserdata)
    ```
    {
      "env": {
        "SKYTAP_USERNAME": "YOUR_USERNAME_HERE",
        "SKYTAP_TOKEN": "YOUR_TOKEN_HERE"
      }
    }
    ```
  - Save the environment as a new template
  - Copy the new template to any additional regions
  - Add the script host VM to your training lab templates
  - Add a tag to each training lab template with format `target_environment_id: XYZ`, where XYZ is the target environment ID

### Set up Course Manager

  - Download the script archive [here](../tunnel.zip)
  - Log into Course Manager as an admin user
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
      - Script name: "tunnel.zip"
      - VMs to start before running the script: "Start only the Script Host VM"
      - Failure behavior: "Do not compplete subsequent provision steps"
      - Timeout (seconds): 600
- Test the script
  - Create a new lab from the course
  - Wait for the provision to finish
  - There should now be a network route between the environments

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
