#!/usr/bin/env python

# Copyright 2022 Skytap Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from skytap_metadata import SkytapMetadata
from lab_control import LabControl

print(f'Welcome to {LabControl().control_data()["title"]}')

print(f'This Skytap environment is {SkytapMetadata().metadata()["configuration_url"]}')

# Note: custom data attributes must be configured in Course Manager settings to be saved; see README.md
LabControl().update_control_data({ "integration_data": { "AcmeDataProUsername": "user_assigned_from_script", "AcmeDataProPassword": "password_assigned_from_script" } })

LabControl().refresh_content_pane()

print(f'Integration data updated to {LabControl().control_data()["integration_data"]}')