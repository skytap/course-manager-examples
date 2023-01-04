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

require "json"
require "net/http"

class APIHelper
  class OperationFailedError < StandardError; end

  def self.rest_call(url, verb, data=nil)
    uri = URI(url)
    host, port, path = uri.host, uri.port, uri.path
    path = "/" if path == ""

    http = Net::HTTP.new(host, port)
    http.use_ssl = true if uri.instance_of?(URI::HTTPS)
    
    req = Object.const_get("Net::HTTP::#{verb.capitalize}").new(path)
    req.body = data&.to_json
    req["Content-Type"] = "application/json"
    
    result = http.request(req)
    raise OperationFailedError, "#{result.code} #{result.message}" unless result.code == "200"
    result.body
  end
end