# Cloud Scripts - Python Script Template for Course Manager

This is a code template that can be used as a starting point for developing a Cloud Scripts script for Course Manager in Python.

## Using This Template

* `script.py` is the entry point of your script -- replace the sample code it contains with your own. You're welcome to add other files and directories under lib/ for use in the script.
* Add any pip packages required by your script to `requirements.txt`.
* Refer to the Cloud Scripts documentation for information about:
  * Building, running, and pushing scripts built with this template using the cloudscripts command-line tool
  * Options to further customize of the runtime environment

## Interacting with Course Manager From Your Script

The Course Manager Control Endpoint provides metadata oriented around the end user lab itself, and it also allows limited modifications of the metadata and state of the lab. This template a `LabControl` class, which provide a lightweight interface to the Control Endpoint that can be used from your script code.

### LabControl Interface
The `LabControl` class is required in your `script.py` by default:

```
from lab_control import LabControl
```

`LabControl` is a singleton. To use it, get a reference to its instance:

```
control = LabControl.get()
```

Then, you can call methods as follows:

```
control.control_data()                                             # => returns control metadata as a hash
control.update_control_data(data)                                  # => updates control data (see below)
control.refresh_content_pane()                                     # => requests any open content panes for the lab to refresh
control.refresh_lab()                                              # => requests any open learning consoles for the lab to refresh their Kyndryl Cloud Uplift environment view
control.find_metadata_attr('myMetadataKey')                        # => finds and returns a standard or sensitive metadata attribute with the specified name on the lab / event participant, event, course, user, or feature, in that order
control.find_metadata_attr('myMetadataKey', 'metadata')            # => same as above but limited to standard metadata
control.find_metadata_attr('myMetadataKey', 'sensitive_metadata')  # => same as above but limited to sensitive metadata
```

#### Updating Control Data

The `update_control_data` method can be used to achieve the following:

Change runstate:
```
control.update_control_data({ "runstate": "running" })    # or "suspended", "halted", "stopped"
```

Update metadata or sensitive metadata:
```
control.update_control_data({ "metadata": { "AcmeDataProUsername": "user_assigned_from_script" }, "sensitive_metadata": { "AcmeDataProPassword": "password_assigned_from_script" } })
```

Update metadata or sensitive metadata for the associated `course`, `feature` (Events or Labs), `event` (for event participants only), or `user` (for on-demand labs provisioned via the [Request Portal workflow](https://help.skytap.com/course-manager-use-request-portal.html) only):

```
control.update_control_data({ "course": { "metadata": { "course_last_provisioned": "07/17/2023 17:48:32"} }, "feature": { "sensitive_metadata": { "password": 'secret'} } })
```

### Control Data Stubbing for Local Development

A challenge in developing scripts that interact with lab metadata is that it is only available from within a Kyndryl Cloud Uplift environment. To help with this, the `bin/run` script runs a "metadata stub" service, simulating the behavior of the Metadata Service and Control Endpoint locally and returning stubbed data. If you would like to modify the stubbed data returned when running your script locally, simply modify the files in `lib/script_support/stub_data`.

## License

Copyright 2026 Kyndryl Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
