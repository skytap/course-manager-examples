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

require 'oauth'

class Assessment
  class ServerError < StandardError; end
  attr_accessor :oauth_consumer_key, :oauth_secret, :lis_result_sourcedid, :lis_outcome_service_url

  def initialize(oauth_consumer_key:, oauth_secret:, lis_result_sourcedid:, lis_outcome_service_url:)
    @oauth_consumer_key = oauth_consumer_key
    @oauth_secret = oauth_secret
    @lis_result_sourcedid = lis_result_sourcedid
    @lis_outcome_service_url = lis_outcome_service_url
  end

  def set_value(value)
    xml = %{<?xml version="1.0" encoding="UTF-8"?>
    <imsx_POXEnvelopeRequest xmlns="http://www.imsglobal.org/lis/oms1p0/pox">
    <imsx_POXHeader>
      <imsx_POXRequestHeaderInfo>
        <imsx_version>V1.0</imsx_version>
        <imsx_messageIdentifier>12341234</imsx_messageIdentifier>
      </imsx_POXRequestHeaderInfo>
    </imsx_POXHeader>
    <imsx_POXBody>
      <replaceResultRequest>
        <resultRecord>
          <sourcedGUID>
            <sourcedId>#{lis_result_sourcedid}</sourcedId>
          </sourcedGUID>
          <result>
            <resultScore>
              <language>en</language>
              <textString>#{value}</textString>
            </resultScore>
          </result>
        </resultRecord>
      </replaceResultRequest>
    </imsx_POXBody>
    </imsx_POXEnvelopeRequest>
    }

    post_xml_message(xml)
    value
  end

  def post_xml_message(xml)
    consumer = OAuth::Consumer.new(oauth_consumer_key, oauth_secret)
    token = OAuth::AccessToken.new(consumer)

    response = token.post(lis_outcome_service_url, xml, 'Content-Type' => 'application/xml')

    if response.body.match(/\bsuccess\b/)
      response.body
    else
      raise Assessment::ServerError, "Success message not found in body: #{response.body}"
    end
  end
end