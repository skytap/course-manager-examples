# Bash Script Template

This is a code template that can be used as a starting point for developing a Course Manager Script in Bash.

## Requirements

This template and the supporting scripts should work on Linux and macOS. 

In addition, building a script from this template requires Docker to run containers. The `docker` utility should be on your system path.

Access to the Course Manager API is required to build and publish packages to Course Manager. Before getting started, login as an administrator to Course Manager, access Admin menu > API keys, and create a new API key/secret pair to use. If you do not see this menu option, please contact Skytap Support to have API access enabled for your account.

Scripts developed from this template require **Course Manager Script Host v10 or higher** for full compatibility.

## Using This Template

* Make a copy of this template to a new directory, ensuring that symlinks are followed (e.g. using `cp -rL`). It may be most convenient to download a fresh copy using a command like:
    ```
    curl -LO https://github.com/skytap/course-manager-examples/raw/master/script-templates/bash.zip && unzip -d myscript bash.zip
    ```
* The `script` directory is where your code will go. `script/script` is the entry point -- replace the sample code it contains with your own. You're welcome to add other files and directories under `script/` for use in the script.
* To test running your script, run the `bin/run` command. This will run your code in a container, in a fashion similar to that used by the Script Host.
* To publish your script to Course Manager, run `bin/publish`. This will build the dependencies, create a ZIP package, and push it to your Course Manager course. Upon first run, you will be prompted for the necessary details, which will be saved in a ` .publish.yml` file for subsequent runs.

## Accessing Metadata & Control Endpoint From Your Script

The Skytap Metadata Service provides read-only metadata about the Skytap environment hosting an end user's lab. The Course Manager Control Endpoint provides metadata oriented around the end user lab itself, and it also allows limited modifications of the metadata and state of the lab.

The Metadata Service and Control Endpoint can be accessed from within your scripts using HTTP API calls. For more information, please [click here](../README.md#accessing-metadata--control-endpoint-from-your-script).

### Metadata Stub Service

A challenge in developing scripts that interact with lab metadata is that it is only available from within a Skytap environment. To help with this, the `bin/run` script runs a "metadata stub" service, simulating the behavior of the Metadata Service and Control Endpoint locally and returning stubbed data. If you would like to modify the stubbed data returned when running your script locally, simply modify the files in `lib/script_support/stub_data`.

**Important**: To ensure that your scripts can be run both locally and in your Course Manager labs, please take note of the following:

* Scripts should always access the Metadata Service via the URL **http://skytap-metadata/skytap**. This is a special URL that only works in Course Manager scripts. This should work in scripts run locally with `bin/run`, as well as from the Script Host in Course Manager-deployed labs (beginning with Script Host v10).
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
