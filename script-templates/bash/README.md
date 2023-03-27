# Bash Script Template

This is a code template that can be used as a starting point for developing a Course Manager Script in Bash.

## Requirements

This template and the supporting scripts should work on Linux and macOS. 

In addition, building a script from this template requires Docker Desktop, Podman or a similar utility to run containers. The `docker` or `podman` utility should be on your system path.

Access to the Course Manager API is required to build and publish packages to Course Manager. Before getting started, login as an administrator to Course Manager, access Admin menu > API keys, and create a new API key/secret pair to use. If you do not see this menu option, please contact Skytap Support to have API access enabled for your account.

Scripts developed from this template require **Course Manager Script Host v10 or higher** for full compatibility.

## Using This Template

* Make a copy of this directory structure and rename the directory to your desired script name.
* The `script` directory is where your code will go. `script/script` is the entry point -- replace the sample code it contains with your own. You're welcome to add other files and directories under `script/` for use in the script.
* To test running your script, run the `bin/run` command. This will run your code in a container, in a fashion similar to that used by the Script Host.
* ~~COMING SOON: To publish your script to Course Manager, run `bin/publish`. This will build the dependencies, create a ZIP package, and push it to your Course Manager course. Upon first run, you will be prompted for the necessary details, which will be saved in a ` .publish.yml` file for subsequent runs.~~
* To publish your script to Course Manager, first run `bin/build`. Then create a ZIP archive from this directory and upload it to the Scripts page. The ZIP file should be created with symlinks followed (i.e. the package should include the actual files, not symlinks) and this file should reside in the root of the archive, not nested in another directory.

## Accessing Metadata & Control Endpoint From Your Script

The Skytap Metadata Service provides read-only metadata about the Skytap environment hosting an end user's lab. The Course Manager Control Endpoint provides metadata oriented around the end user lab itself, and it also allows limited modifications of the metadata and state of the lab.

### Skytap Metadata Service

Access the Metadata Service using the URL `http://skytap-metadata/skytap` from your script. Please do not use other URLs to access it (see "Metadata Stub Service" section for more details). 

For example:

```
curl -s http://skytap-metadata/skytap # => { "id":"11111111", "name":"Windows Server 2019 Datacenter" ...,}
```

### Lab Control Endpoint

The URL for the Lab Control Endpoint must be retrieved from the Skytap Metadata Service. For example:

```
CONTROL_URL=$(curl -s http://skytap-metadata/skytap|jq -r ".user_data | fromjson | .control_url")
```

That URL, can then be accessed from your script:

```
curl -s $CONTROL_URL # => { "id":360, "consumed_at":null, ... }
```


#### Updating Custom Data

```
curl -s -X PUT $CONTROL_URL -d '{"integration_data": {"AcmeDataProUsername":"user_assigned_from_script", "AcmeDataProPassword":"password_assigned_from_script"}}'
```

Please note:
* Custom data fields must be created on the Admin > Settings page (under Labs > Integrations > Custom Data) before they can be updated.
* Updating custom data overwrites all existing integration data for the lab. If you wish to only update a subset of the integration data fields, retrieve the old integration data, merge your changes in, and then update with the result.


#### Changing Runstate

```
curl -s -X PUT $CONTROL_URL -d '{"runstate": "running"}' # or "suspended", "halted", "stopped"
```

#### Refreshing the Content or Environment Pane (within Learning Console)

To refresh either the Content or Environment pane within any open Learning Console instances for a given lab, first determine the broadcast URL. This is easiest done by appending `/learning_console/broadcast` to the user access URL as it appears in the Control Endpoint payload. This can be done with logic like:

```
CONTROL_URL=$(curl -s http://skytap-metadata/skytap|jq -r ".user_data | fromjson | .control_url")
CONTROL_DATA=$(curl -s $CONTROL_URL)
BROADCAST_URL=$(echo $CONTROL_DATA | jq -r .user_access_url)/learning_console/broadcast
```

From there, try one of the following:

```
curl -s -X POST $BROADCAST_URL -d '{"type":"refresh_content_pane"}'
curl -s -X POST $BROADCAST_URL -d '{"type":"refresh_lab"}'
```

### Metadata Stub Service

A challenge in developing scripts that interact with lab metadata is that it is only available from within a Skytap environment. To help with this, the `bin/run` script runs a "metadata stub" service, simulating the behavior of the Metadata Service and Control Endpoint locally and returning stubbed data. If you would like to modify the stubbed data returned when running your script locally, copy the `../lib/metadata_stub_server/lib/stub_data` directory to `lib/script_support/stub_data` and modify the files accordingly.

**Important**: To ensure that your scripts can be run both locally and in Skytap, please take note of the following:

* Scripts should always access the Metadata Service via the URL **http://skytap-metadata/skytap**. This is a special URL that only works in Course Manager scripts. This should work in scripts run with `bin/run`, as well as from the Script Host in Course Manager-deployed labs (beginning with Script Host v10).
* If your code accesses to the Lab Control endpoint, note that the endpoint URL used by the Metadata Stub Service will use http, but in production, the Lab Control endpoint will use https. Your code should always retrieve the Lab Control endpoint from the Metadata Service as shown above, expect that it may use either HTTP or HTTPS, and function accordingly.


## License

Copyright 2023 Skytap Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
