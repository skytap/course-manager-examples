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

The Skytap Metadata Service provides read-only metadata about the Skytap environment hosting an end user's lab. The Course Manager Control Endpoint provides metadata oriented around the end user lab itself, and it also allows limited modifications of the metadata and state of the lab.

The Metadata class, included in your `script.rb` by default, provides a lightweight interface to access both of these services. Simply instantiate a Metadata object:

```
metadata = Metadata.new
```

Then, you can call methods on the object as follows:

```
metadata.metadata                               # => returns Skytap metadata as a hash
metadata.user_data                              # => parses the Skytap metadata's "user_data" attribute, which is typically JSON for Course Manager-provisioned labs, as a hash and then returns it
metadata.configuration_user_data                # => parses the Skytap metadata's "configuration_user_data" attribute, which is typically JSON for Course Manager-provisioned labs, as a hash and returns it
metadata.control_data                           # => returns Course Manager lab metadata as a hash
metadata.update_control_data(hash_of_changes)   # => modifies Course Manager lab metadata and state
```

One challenge in developing against this data is these endpoints are available only to scripts running in a Skytap environment -- but many customers may prefer to develop their scripts locally. To aid with this, the Metadata class can transparently return "stubbed" data when your script is run outside of Skytap. The stub data returned is defined in the `lib/stub_data` directory. Feel free to modify the stub data if you wish.

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
