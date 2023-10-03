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

require 'json'
require 'uri'
require 'net/http'
require 'base64'

class SkytapClient
  class SkytapError < StandardError; end

  def initialize(username, api_token)
    base_uri = URI('https://cloud.skytap.com')
    @auth_header = "Basic #{Base64.strict_encode64("#{username}:#{api_token}")}"
    @http = Net::HTTP.new(base_uri.host, base_uri.port)
    @http.use_ssl = true
  end

  def get(url)
    call(url, Net::HTTP::Get)
  end

  def post(url, data)
    call(url, Net::HTTP::Post, data)
  end

  def put(url, data)
    call(url, Net::HTTP::Put, data)
  end

  def delete(url)
    call(url, Net::HTTP::Delete)
  end

  def wait_until_not_busy(url)
    loop do
      resource = get(url)
      return if resource['runstate'] != 'busy' && resource['busy'] != true
    end
  end

  private

  def call(url, request_class, data = nil)
    uri = URI(url)
    path = uri.path
    path = "/" if path == ""
    data = data.to_json unless data.kind_of?(String)

    req = request_class.new(uri)
    req['Accept'] = 'application/json'
    req['Content-Type'] = 'application/json'
    req['Authorization'] = @auth_header

    response = @http.request(req, data)

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      # OK
    else
      raise SkytapError.new(response.class.name)
    end

    JSON.parse(response.body)
  end
end