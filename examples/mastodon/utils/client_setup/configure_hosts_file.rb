# Copyright 2023 Skytap Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'net/http'
require 'json'

potential_hosts_files = ['/etc/hosts', 'c:/windows/system32/drivers/etc/hosts']
hosts_file = potential_hosts_files.detect {|f| File.exist?(f)}
exit 1 unless hosts_file

skytap_metadata = JSON.parse(Net::HTTP.get(URI("http://gw/skytap")))
user_data = JSON.parse(skytap_metadata['configuration_user_data'])
metadata_url = user_data['metadata_url']
metadata = JSON.parse(Net::HTTP.get(URI(metadata_url)))
ip = metadata.dig('metadata', 'mastodon_server_ip')
fqdn = metadata.dig('metadata', 'lab_fqdn')
exit 1 unless ip && fqdn

new_line = "#{ip} #{fqdn}\n"

unless File.read(hosts_file).include?(new_line)
  open(hosts_file, 'a') {|f| f.puts(new_line)}
end

exit 0
