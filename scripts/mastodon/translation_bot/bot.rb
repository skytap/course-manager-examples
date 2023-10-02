# require 'mastodon'
# require 'websocket-client-simple'

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
  SKYTAP_METADATA_URI = 'http://169.254.169.254/skytap'

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
    # 'Ocp-Apim-Subscription-Key': @translator_token, 
      # 'Ocp-Apim-Subscription-Region' => @translator_region
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