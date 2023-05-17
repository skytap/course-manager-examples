# Course Manager Script Templates

## Getting Started

A Course Manager script is simply a ZIP package that contains a configuration file called `config.yml` at its root. The contents of the script package are extracted and mounted into a Docker container, where they are run.

While a script can be developed from scratch, we recommend using one of our script templates as a starting point for your development. Scripts can be created, tested locally, and published to Course Manager using the templates and the tools provided with them. Please see the README file provided with each template for details on getting started.

| Template Name | Download | Browse |
| -------- | -------- | ------ |
| Bash     | [Download](https://github.com/skytap/course-manager-examples/raw/master/script-templates/bash.zip) | [Browse](https://github.com/skytap/course-manager-examples/tree/master/script-templates/bash) |
| NodeJS   | [Download](https://github.com/skytap/course-manager-examples/raw/master/script-templates/node.zip) | [Browse](https://github.com/skytap/course-manager-examples/tree/master/script-templates/node) |
| Python   | [Download](https://github.com/skytap/course-manager-examples/raw/master/script-templates/python.zip) | [Browse](https://github.com/skytap/course-manager-examples/tree/master/script-templates/python) |
| Ruby     | [Download](https://github.com/skytap/course-manager-examples/raw/master/script-templates/ruby.zip) | [Browse](https://github.com/skytap/course-manager-examples/tree/master/script-templates/ruby) |

## Advanced Script Configuration

While not necessary in most cases, the following options can be configured in the `config.yml` file of your script.

### Specifying a Container Image

#### Using a Built-In Container Image
|Name|Type|Description|
|----|----|-----------|
|runtime|String|The name of the built-in container image to be used.<br/><br/>The built-in images available currently include **debian:bullseye**, **node:18.14-bullseye**, **python:3.11-bullseye** and **ruby:3.2-bullseye**.|

**OR**

#### Using a Non-Built-In Container Image
|Name|Type|Description|
|----|----|-----------|
|image_name|String|The name or URL of the non-built-in container image in which the script should be extracted and executed.<br/><br/>**Warning!** Docker Hub and other popular container registries impose rate limits on image downloads. Because the container image will be downloaded into each lab where it's used, it's easy to hit such rate limits, which will result in script execution to fail. When using a non-built-in container image, we highly recommend that you self-host the image in your own registry and that image size be kept to a minimum.|
|registry_username|String|The username to be used for authentication to the registry where the specified image resides, if any.|
|registry_username|String|The password to be used for authentication to the registry where the specified image resides, if any.|

### Configuring the Command to Be Executed
|Name|Type|Description|
|----|----|-----------|
|command|String|The command to be executed to invoke the script inside the container, provided as an array of string tokens (e.g. `["/bin/bash", "./script", "--arg1"]`)|
|disable_entrypoint|Boolean|Specifies whether the container image's entrypoint should be blanked out. This may be necessary if you want to use a non-built-in container image that was built with an ENTRYPOINT and you want to override the command. _Defaults to false_|

### Other Configuration
|Name|Type|Description|
|----|----|-----------|
|script_dir_writable|Boolean|Specifies whether the script should have write access to the directory in which it will reside and from which it will be run. Changing this setting is not recommended. Please see "Managing Data During Script Invocation" for further details. _Defaults to false_|
|env|Hash|Specifies environment variables to be exposed to the running script (e.g. `{"var1":"val1","var2":"val2"}`)|

## Managing Data during Script Invocation
The script will be extracted into its own directory from which it will be run. This directory is mounted read-only by default. While this can be changed (see "Other Configuration"), doing so is discouraged. This is because a script could inadvertently modify its own files, which could impact subsequent executions of the script within the same lab.

If a script needs "scratch space," scripts can write files to the `/script_data` directory. Data stored in this location is persistent between script runs. However, the Script Host itself is not guaranteed to be persistent – for example, it could be redeployed as part of a re-provision operation. As such, it is recommended that data important to the operation of the lab – such as details about resources provisioned from a script that need to be re-accessed or cleaned up later – be persisted externally to the script (for example, in Course Manager custom data fields).

## Accessing Metadata & Control Endpoint From Your Script

The Skytap Metadata Service provides read-only metadata about the Skytap environment hosting an end user's lab. The Course Manager Control Endpoint provides metadata oriented around the end user lab itself, and it also allows limited modifications of the metadata and state of the lab.

The Metadata Service and Control Endpoint can be accessed from within your scripts using HTTP API calls as described below. In addition, the Ruby, Node and Python script templates provide language-specific libraries that wrap the HTTP APIs, making it easier to consume these services. Please consult the README file for the respective template for details.

### Skytap Metadata Service

Access the Metadata Service using the URL `http://skytap-metadata/skytap` from your script. This is a special URL that only works from within Course Manager scripts.

#### Getting the Skytap Metadata

Request:
```
GET http://skytap-metadata/skytap
Accept: application/json
```

Response:
```
200 OK

{"id":"11111111", "name":"Windows Server 2019 Datacenter", "user_data":"{\"control_url\":\"https://customername.skytap-portal.com/lab_access/self_learner/360/.../control/...\"}", ...}
```

### Lab Control Endpoint

To use the Lab Control Endpoint, your script must first retrieve its URL from the Skytap metadata. Get the Skytap metadata from the Metadata Service as described above and parse the JSON payload. Extract the `user_data` attribute, and parse the JSON string it contains. From there, you can extract the `control_url` attribute, which represents the Lab Control Endpoint.

#### Getting the Lab Control metadata

Request:
```
GET https://customername.skytap-portal.com/lab_access/self_learner/360/.../control/...
Accept: application/json

Response:
200 OK

{"id":360, "consumed_at":null, "user_identifier":"user@domain.com", "user_access_url":"https://customername.skytap-portal.com/lab_access/self_learner/360/...", ... }
```

#### Updating Custom Data

Request:
```
PUT https://customername.skytap-portal.com/lab_access/self_learner/360/.../control/...
Content-Type: application/json
Accept: application/json

{"integration_data": {"AcmeDataProUsername":"user_assigned_from_script","AcmeDataProPassword":"password_assigned_from_script"}}
```

Response:
```
200 OK

{"id":360, "consumed_at":null, "user_identifier":"user@domain.com", "user_access_url":"https://customername.skytap-portal.com/lab_access/self_learner/360/...", ... }
```

Please note:
* Custom data fields must be created on the Admin > Settings page (under Labs > Integrations > Custom Data) before they can be updated.
* Updating custom data overwrites all existing integration data for the lab. If you wish to only update a subset of the integration data fields, retrieve the old integration data, merge your changes in, and then update with the result.

#### Changing Runstate
You can set the runstate to "running", "suspended", "halted" or "stopped" (see definitions [here](https://help.skytap.com/API_Documentation.html#Run/Stop) as follows:

Request:
```
PUT https://customername.skytap-portal.com/lab_access/self_learner/360/.../control/...
Content-Type: application/json
Accept: application/json

{"runstate": "running"}
```

Response:
```
200 OK

{"id":360, "consumed_at":null, "user_identifier":"user@domain.com", "user_access_url":"https://customername.skytap-portal.com/lab_access/self_learner/360/...", ... }
```

#### Refreshing the Content or Environment Pane (within Learning Console)

To refresh either the Content or Environment pane within any open Learning Console instances for a given lab, first determine the broadcast URL. This is done by appending `/learning_console/broadcast` to the user access URL as it appears in the Control Endpoint payload. Then, send a message to the broadcast URL with a type of "refresh_content_pane" or "refresh_lab" as follows:

Request:
```
PUT https://customername.skytap-portal.com/lab_access/self_learner/360/.../learning_console/broadcast
Content-Type: application/json
Accept: application/json

{"type": "refresh_content_pane"}
```

Response:
```
200 OK

{"id":360, "consumed_at":null, "user_identifier":"user@domain.com", "user_access_url":"https://customername.skytap-portal.com/lab_access/self_learner/360/...", ... }
```

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
