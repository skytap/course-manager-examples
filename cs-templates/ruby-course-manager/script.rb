# Copyright 2026 Kyndryl Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "lab_control"

$stdout.sync = true
$stderr.sync = true

lab_control = LabControl.get

puts "Welcome to #{lab_control.control_data['title']}!"
puts "This Kyndryl Cloud Uplift environment ID is #{lab_control.control_data['skytap_environment_id']}"

lab_control.update_control_data({ "metadata" => { "AcmeDataProUsername" => "user_assigned_from_script" }, "sensitive_metadata" => { "AcmeDataProPassword" => "password_assigned_from_script" } })

puts "Metadata updated to #{lab_control.control_data['metadata']}"
puts "Sensitive metadata updated to #{lab_control.control_data['sensitive_metadata']} (displayed for demo purposes only -- sensitive metadata is not normally intended for exposure to end users!)"