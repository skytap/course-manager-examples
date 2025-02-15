#!/usr/bin/env python

# Copyright 2025 Skytap Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from lab_control import LabControl

lab_control = LabControl.get()

print(f'Welcome to {lab_control.control_data()["title"]}')
print(f'This Skytap environment ID is {lab_control.control_data()["skytap_environment_id"]}')

lab_control.update_control_data({ "metadata": { "AcmeDataProUsername": "user_assigned_from_script"}, "sensitive_metadata": { "AcmeDataProPassword": "password_assigned_from_script" } })

print(f'Metadata updated to {lab_control.control_data()["metadata"]}')
print(f'Sensitive metadata updated to {lab_control.control_data()["sensitive_metadata"]} (displayed for demo purposes only -- sensitive metadata is not normally intended for exposure to end users!)')