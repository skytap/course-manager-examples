# Python Script Template

This is a code template that can be used as a starting point for developing a Course Manager Script in Python.

## Requirements

This template and the supporting scripts should work on Linux and macOS. 

In addition, building a script from this template requires Docker Desktop, Podman or a similar utility to run containers. The `docker` or `podman` utility should be on your system path.

Access to the Course Manager API is required to build and publish packages to Course Manager. Before getting started, login as an administrator to Course Manager, access Admin menu > API keys, and create a new API key/secret pair to use. If you do not see this menu option, please contact Skytap Support to have API access enabled for your account.

Scripts developed from this template require **Course Manager Script Host v10 or higher** for full compatibility.

## Using This Template

* Make a copy of this directory structure and rename the directory to your desired script name.
* The `script` directory is where your code will go. `script/script.py` is the entry point -- replace the sample code it contains with your own. You're welcome to add other files and directories under `script/` for use in the script.
* Add any pip packages required by your script to `script/requirements.txt`. Packages will be built in a Linux container to ensure the architecture matches the runtime environment of the Script Host.
* To test running your script, run the `bin/run` command. This will run your code in a container, in a fashion similar to that used by the Script Host.
* ~~COMING SOON: To publish your script to Course Manager, run `bin/publish`. This will build the dependencies, create a ZIP package, and push it to your Course Manager course. Upon first run, you will be prompted for the necessary details, which will be saved in a ` .publish.yml` file for subsequent runs.~~
* To publish your script to Course Manager, first run `bin/build`. Then create a ZIP archive from this directory and upload it to the Scripts page. The ZIP file should be created with symlinks followed (i.e. the package should include the actual files, not symlinks) and this file should reside in the root of the archive, not nested in another directory.

## Accessing Metadata & Control Endpoint From Your Script

The Skytap Metadata Service provides read-only metadata about the Skytap environment hosting an end user's lab. The Course Manager Control Endpoint provides metadata oriented around the end user lab itself, and it also allows limited modifications of the metadata and state of the lab. This template provides `SkytapMetadata` and `LabControl` classes, which provide lightweight interfaces to these two service endpoints that can be used from your script code. These classes make it easier to consume the Metadata and Control Endpoint services. In addition, they make it easier to develop your scripts locally.

### SkytapMetadata Interface

The `SkytapMetadata` class is required in your `script.py` by default:

```
from skytap_metadata import SkytapMetadata
```

`SkytapMetadata` is a singleton. To use it, get a reference to its instance:

```
metadata = SkytapMetadata()
```

Then, you can call methods as follows:

```
metadata.metadata()                               # => returns Skytap metadata as a hash
metadata.user_data()                              # => parses the Skytap metadata's "user_data" attribute, which is typically JSON for Course Manager-provisioned labs, as a hash and then returns it
metadata.configuration_user_data()                # => parses the Skytap metadata's "configuration_user_data" attribute, which is typically JSON for Course Manager-provisioned labs, as a hash and returns it
metadata.control_url()                            # => returns the control endpoint URL
```

### LabControl Interface
The `LabControl` class is required in your `script.py` by default:

```
from lab_control import LabControl
```

`LabControl` is a singleton. To use it, get a reference to its instance:

```
control = LabControl()
```

Then, you can call methods as follows:

```
control.control_data()                            # => returns control metadata as a hash
control.update_control_data(data)                 # => updates control data (see below)
control.refresh_content_pane()                    # => requests any open content panes for the lab to refresh
control.refresh_lab()                             # => requests any open learning consoles for the lab to refresh their Skytap environment view
```

#### Updating control data

The `update_control_data` method can be used to achieve the following:

Change runstate:
```
control.update_control_data("runstate": "running")    # or "suspended", "halted", "stopped"
```

Update custom data:
```
control.update_control_data("integration_data": { "acme_username": "user001", "acme_password": "password123!" })
```

Please note:
* Custom data fields must be created on the Admin > Settings page (under Labs > Integrations > Custom Data) before they can be updated.
* Updating custom data overwrites all existing integration data for the lab. If you wish to only update a subset of the integration data fields, retrieve the old integration data, merge your changes in, and then update with the result.

### Metadata Stub Service

A challenge in developing scripts that interact with lab metadata is that it is only available from within a Skytap environment. To help with this, the `bin/run` script runs a "metadata stub" service, simulating the behavior of the Metadata Service and Control Endpoint locally and returning stubbed data. If you would like to modify the stubbed data returned when running your script locally, copy the `../lib/metadata_stub_server/lib/script_support/stub_data` directory to `lib/script_support/stub_data` and modify the files accordingly.

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