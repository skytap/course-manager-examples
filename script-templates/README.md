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
|registry_password|String|The password to be used for authentication to the registry where the specified image resides, if any.|

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

## Managing Data During Script Invocation
The script will be extracted into its own directory from which it will be run. This directory is mounted read-only by default. While this can be changed (see "Other Configuration"), doing so is discouraged. This is because a script could inadvertently modify its own files, which could impact subsequent executions of the script within the same lab.

If a script needs "scratch space," scripts can write files to the `/script_data` directory. Data stored in this location is persistent between script runs. However, the Script Host itself is not guaranteed to be persistent – for example, it could be redeployed as part of a re-provision operation. As such, it is recommended that data important to the operation of the lab – such as details about resources provisioned from a script that need to be re-accessed or cleaned up later – be persisted externally to the script (for example, in Course Manager custom data fields).

## Accessing Metadata & Control Endpoint From Your Script

The Skytap Metadata Service provides read-only metadata about the Skytap environment hosting an end user's lab. The Course Manager Control Endpoint provides metadata oriented around the end user lab itself, and it also allows limited modifications of the metadata and state of the lab.

The Metadata Service and Control Endpoint can be accessed from within your scripts via HTTP API calls using `curl` within the Bash script template or language-specific libraries within the Ruby, Node and Python script templates. Please consult the README file for the respective template for details.

## Testing Your Script

Several options are available for testing that your script works as expected:

### Use the Script Template's `bin/run` Utility
If you use a script template to build your script, the `bin/run` utility allows you to test the script locally. Please see the README file provided with the respective script template for details.

### Test in a Live Lab
You always have the option to test your script in a live Course Manager lab. This involves publishing the script to your course, provisioning a test lab, running the script, and observing its behavior.

Whenever a script is invoked within a lab, the latest version is used. This allows for an iterative development/test process in which you can provision a single test lab, and upload, test, re-upload, and re-test your scripts as many times as you need.

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
