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

require 'faye/websocket'
require 'eventmachine'
require 'http'
require 'dotenv/load'

class TranslationBot
  PREFIXES = {
    'en' => 'Translation:',
    'es' => 'Traducción:'
  }.freeze

  LANGUAGE_PAIRS = {
    'en' => 'es',
    'es' => 'en'
  }.freeze

  TRANSLATOR_URI = 'https://api.cognitive.microsofttranslator.com/translate'.freeze
  SKYTAP_METADATA_URI = 'http://169.254.169.254/skytap'.freeze

  def initialize()
    @mast_fqdn = ENV['MAST_FQDN']
    @mast_token = ENV['MAST_TOKEN'].strip
    refresh_token
  end

  def refresh_token
    skytap_metadata = JSON.parse(HTTP.get(SKYTAP_METADATA_URI))
    user_data = JSON.parse(skytap_metadata['configuration_user_data'])
    cm_metadata_url = user_data['metadata_url']
    cm_metadata = JSON.parse(HTTP.get(cm_metadata_url))

    @translation_token = cm_metadata['metadata']['translation_token']
  end
  def run
    EM.run do
      puts streaming_url
      ws = Faye::WebSocket::Client.new(streaming_url)
    
      ws.on :open do |event|
        puts 'Connection opened'
      end
    
      ws.on :message do |event|
        h = JSON.parse(event.data)
        if h['event'] == 'update'
          payload = JSON.parse(h['payload'])
          content = payload['content'].gsub(%r(</?[^>]+?>), '')
          status_id = payload['id']
          from_language = payload['language']
          to_language = LANGUAGE_PAIRS[from_language]
          unless content.include? PREFIXES[from_language]
            puts "Translating #{ status_id} from #{from_language} to #{to_language}"
            translation = translate(content, from_language, to_language)
            new_content = "#{ PREFIXES[to_language] } #{ translation }"
            retoot(new_content, to_language, status_id)
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

  def retoot(text, language, in_reply_to_id)
    HTTP.headers(
      Authorization: "Bearer #{ @mast_token }"
    ).post("https://#{ @mast_fqdn }/api/v1/statuses", 
      json: {
        status: text,
        language: language,
        in_reply_to_id: in_reply_to_id
      }
    )
  end

  def translate(text, from, to)  
    response = HTTP.headers(
      Authorization: "Bearer #{ @translation_token }"
    ).post(TRANSLATOR_URI, 
      params: {
        'api-version' => '3.0',
        'from' => from,
        'to' => [to]
      },
      json: [{ 'text' => text }]
    )
    puts response
    return JSON.parse(response).first['translations'].first['text']
  end

  def streaming_url
    "wss://#{ @mast_fqdn }/api/v1/streaming?access_token=#{ @mast_token }&stream=public:local"
  end
end

TranslationBot.new.run