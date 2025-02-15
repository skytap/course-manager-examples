# Skytap Cloud Scripts - Node.js Script Template for Course Manager

This is a code template that can be used as a starting point for developing a Skytap Cloud Scripts script for Course Manager in Node.js.

## Using This Template

* `script.js` is the entry point of your script -- replace the sample code it contains with your own. You're welcome to add other files and directories under lib/ for use in the script.
* Add any npm packages required by your script to `package.json`.
* Refer to the Skytap Cloud Scripts documentation for information about:
  * Building, running, and pushing scripts built with this template using the skytapcs command-line tool
  * Options to further customize of the runtime environment

## Interacting with Course Manager From Your Script

The Course Manager Control Endpoint provides metadata oriented around the end user lab itself, and it also allows limited modifications of the metadata and state of the lab. This template a `LabControl` class, which provide a lightweight interface to the Control Endpoint that can be used from your script code.

### LabControl Interface
The `LabControl` class is required in your `script.js` by default:

```
import LabControl from './lib/labControl.js';
```

`LabControl` is a singleton. To use it, get a reference to its instance:

```
control = LabControl.get()
```

Then, you can call methods as follows. Please note that all methods listed below are **asynchronous**.

```
control.controlData()                                            # => returns control metadata as a hash
control.updateControlData(data)                                  # => updates control data (see below)
control.refreshContentPane()                                     # => requests any open content panes for the lab to refresh
control.refreshLab()                                             # => requests any open learning consoles for the lab to refresh their Skytap environment view
control.findMetadataAttr('myMetadataKey')                        # => finds and returns a standard or sensitive metadata attribute with the specified name on the lab / event participant, event, course, user, or feature, in that order
control.findMetadataAttr('myMetadataKey', 'metadata')            # => same as above but limited to standard metadata
control.findMetadataAttr('myMetadataKey', 'sensitive_metadata')  # => same as above but limited to sensitive metadata
```

#### Updating Control Data

The `updateControlData` method can be used to achieve the following:

Change runstate:
```
control.updateControlData({ "runstate": "running" })    # or "suspended", "halted", "stopped"
```

Update metadata or sensitive metadata:
```
control.updateControlData({ "metadata": { "AcmeDataProUsername": "user_assigned_from_script" }, "sensitive_metadata": { "AcmeDataProPassword": "password_assigned_from_script" } })
```

Update metadata or sensitive metadata for the associated `course`, `feature` (Events or Labs), `event` (for event participants only), or `user` (for on-demand labs provisioned via the [Request Portal workflow](https://help.skytap.com/course-manager-use-request-portal.html) only):

```
control.updateControlData({ "course": { "metadata": { "course_last_provisioned": "07/17/2023 17:48:32"} }, "feature": { "sensitive_metadata": { "password": 'secret'} } })
```

### Control Data Stubbing for Local Development

A challenge in developing scripts that interact with lab metadata is that it is only available from within a Skytap environment. To help with this, the `bin/run` script runs a "metadata stub" service, simulating the behavior of the Metadata Service and Control Endpoint locally and returning stubbed data. If you would like to modify the stubbed data returned when running your script locally, simply modify the files in `lib/script_support/stub_data`.

## License

Copyright 2025 Skytap Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
