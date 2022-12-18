# Ruby Script Template

This is a code template that can be used as a starting point for developing a Course Manager Script in Ruby.

## Requirements

This template and the supporting scripts should work on Linux and macOS. 

In addition, building a script from this template requires Docker Desktop, Podman or a similar utility to run containers. The `docker` or `podman` utility should be on your system path.

## Using This Template

* Make a copy of this directory structure and rename the directory to your desired script name.
* Add any gems required by your script to `Gemfile`. Gems will be built in a Linux container to ensure the architecture matches the runtime environment of the Script Host.
* `script.rb` is the entry point for the script. Feel free to put all your code logic here.
* You can add additional files to the script as well. For example, if you'd like to break your Ruby code into multiple files or include non-gem libraries, that code can be placed in the `lib` directory and included into `script.rb` using `require_relative`.
* To test running your script, run the `utils/run` command. This will run your code in a Linux container to match the runtime environment of the Script Host.
* To package your script into the ZIP format required by Course Manager, use the `utils/package` command. The resulting ZIP file will be placed in the `out/` subdirectory and can be uploaded directly to your course.

## Accessing Metadata & Control Endpoint From Your Script

The Skytap Metadata Service provides read-only metadata about the Skytap environment hosting an end user's lab. The Course Manager Control Endpoint provides metadata oriented around the end user lab itself, and it also allows limited modifications of the metadata and state of the lab. This template provides `SkytapMetadata` and `LabControl` classes, which provide lightweight interfaces to these two service endpoints that can be used from your script code. These classes make it easier to consume the Metadata and Control Endpoint services. In addition, they make it easier to develop your scripts locally.

### SkytapMetadata Interface

The `SkytapMetadata` class is required in your `script.rb` by default:

```
require_relative "lib/skytap_metadata"
```

`SkytapMetadata` is a singleton. To use it, get a reference to its instance:

```
metadata = SkytapMetadata.get
```

Then, you can call methods as follows:

```
metadata.metadata                               # => returns Skytap metadata as a hash
metadata.user_data                              # => parses the Skytap metadata's "user_data" attribute, which is typically JSON for Course Manager-provisioned labs, as a hash and then returns it
metadata.configuration_user_data                # => parses the Skytap metadata's "configuration_user_data" attribute, which is typically JSON for Course Manager-provisioned labs, as a hash and returns it
metadata.control_url                            # => returns the control endpoint URL
```

### LabControl Interface
The `LabControl` class is required in your `script.rb` by default:

```
require_relative "lib/lab_control"
```

`LabControl` is a singleton. To use it, get a reference to its instance:

```
control = LabControl.get
```

Then, you can call methods as follows:

```
control.control_data                            # => returns control metadata as a hash
control.update_control_data(data)               # => updates control data (see below)
control.refresh_content_pane                    # => requests any open content panes for the lab to refresh
control.refresh_lab                             # => requests any open learning consoles for the lab to refresh their Skytap environment view
```

#### Updating control data

The `update_control_data` method can be used to achieve the following:

Change runstate:
```
control.update_control_data(runstate: "running")    # or "suspended", "halted", "stopped"
```

Update custom data:
```
control.update_control_data(integration_data: { acme_username: "user001", acme_password: "password123!" })
```

Please note:
* Custom data fields must be created on the Admin > Settings page (under Labs > Integrations > Custom Data) before they can be updated.
* Updating custom data overwrites all existing integration data for the lab. If you wish to only update a subset of the integration data fields, retrieve the old integration data, merge your changes in, and then update with the result.

### Metadata Stub Service

A chellenge in developing scripts that interact with lab metadata is that it is only available from within a Skytap environment. To help with this, the `utils/run` script runs a "metadata stub" service, simulating the behavior of the Metadata Service and Control Endpoint locally and returning stubbed data. If you would like to modify the stubbed data returned when running your script locally, it is located in the `lib/stub_data` directory.

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
