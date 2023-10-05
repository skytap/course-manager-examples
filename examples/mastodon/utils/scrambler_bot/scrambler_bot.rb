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

require 'dotenv/load'
require 'faye/websocket'
require 'eventmachine'
require 'rest-client'
require 'json'
require 'pry'
require 'rest-client'

class ScramblerBot
  attr_reader :mast_domain, :access_token, :stream_name

  def initialize(mast_domain:, access_token:, stream_name:)
    @mast_domain = mast_domain
    @access_token = access_token
    @stream_name = stream_name
  end

  def run
    EM.run do
      ws = Faye::WebSocket::Client.new(streaming_url)

      ws.on :open do |event|
        puts "Established connection"
      end

      ws.on :message do |event|
        h = JSON.parse(event.data)
        if h['event'] == 'update'
          payload = JSON.parse(h['payload'])
          content = payload['content']
          in_reply_to_id = payload['id']

          unless content.include?("Scrambled!")
            send_scrambled_reply(content:, in_reply_to_id:)
          end
        end
      end

      ws.on :close do |event|
        puts "Closed connection with event code #{event.code}: #{event.reason}"
        run
      end
    end
  end

  private

  def streaming_url
    "wss://#{mast_domain}/api/v1/streaming?access_token=#{access_token}&stream=#{stream_name}"
  end

  def statuses_url
    "https://#{mast_domain}/api/v1/statuses"
  end

  def send_scrambled_reply(content:, in_reply_to_id:)
    status = "Scrambled! #{scramble(content)}"
    RestClient.post statuses_url, {status:, in_reply_to_id:}, {:Authorization => "Bearer #{access_token}"}
  rescue => ex
    puts "Error! #{ex.inspect}"
  end

  def scramble(text)
    text.gsub(%r{</?[^>]+?>}, '').split.shuffle.join(" ")
  end
end

if (missing_vars = (['MAST_ACCESS_TOKEN', 'MAST_DOMAIN'] - ENV.keys)).any?
  STDERR.puts "Please set the following env vars and try again: #{missing_vars.join(',')}"
  exit 1
end

ScramblerBot.new(
  access_token: ENV['MAST_ACCESS_TOKEN'],
  mast_domain: ENV['MAST_DOMAIN'],
  stream_name: "public:local"
).run