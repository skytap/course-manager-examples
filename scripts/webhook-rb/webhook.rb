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

require 'rest-client'
require 'json'

WEBHOOK_ENDPOINT = ENV['WEBHOOK_ENDPOINT']

metadata = JSON.parse(RestClient.get("http://169.254.169.254/skytap").body)
control_url = JSON.parse(metadata["user_data"])["control_url"]
control_data = JSON.parse(RestClient.get(control_url).body)

message = <<~EOF
  Hear ye, hear ye!
  A user has finished a lab activity at #{Time.now}.
  They go by the moniker of #{control_data["user_identifier"]}
  The course completed is #{control_data["course_identifier"]}
  They have completed #{control_data["course_manual_readership"]["last_completed_page"]} out of #{control_data["course_manual_version"]["page_count"]}
EOF

RestClient.post(WEBHOOK_ENDPOINT, message, content_type: :json)