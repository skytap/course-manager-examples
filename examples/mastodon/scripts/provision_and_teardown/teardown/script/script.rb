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

require "skytap_metadata"
require "lab_control"
require "ruby_terraform"
require "terraform_helper"
require "assessment"
require "sendgrid-ruby"
require "httplog"
require 'exam_grader'

include SendGrid

HttpLog.configure { |config| config.enabled = false }

skytap_metadata = SkytapMetadata.get
lab_control = LabControl.get
control_data = lab_control.control_data

if lab_control.find_metadata_attr('http_debug') == '1'
  HttpLog.configure { |config| config.enabled = true }
end

subscription_id = lab_control.find_metadata_attr('azure_subscription_id')
tenant_id = lab_control.find_metadata_attr('azure_tenant_id')
client_id = lab_control.find_metadata_attr('azure_client_id')
client_secret = lab_control.find_metadata_attr('azure_client_secret')
storage_account = lab_control.find_metadata_attr('azure_storage_account')
container = lab_control.find_metadata_attr('azure_container')
resource_group = lab_control.find_metadata_attr('azure_resource_group')
lab_id = lab_control.find_metadata_attr('lab_id')
sendgrid_key = lab_control.find_metadata_attr('sendgrid_key')
instructor_email = lab_control.find_metadata_attr('instructor_email')
lti_data = lab_control.find_metadata_attr('lti_data')
lti_key = lab_control.find_metadata_attr('lti_key')
lti_secret = lab_control.find_metadata_attr('lti_secret')
user_email = control_data['user_identifier']
lab_score = lab_control.find_metadata_attr('lab_score') 

if lab_score
  puts "The lab has already been graded. Skipping grading."
else
  grader_result = ExamGrader.new.grade_exam

  max_score = 100
  
  user_score = grader_result[:total_score]

  puts "The user's score is #{user_score} out of #{max_score}"
  
  puts "Sending score to user and instructor..."

  mail = SendGrid::Mail.new
  mail.subject = 'Your lab has been graded'
  mail.from = SendGrid::Email.new(email: 'noreply@skytap-portal.com')
  mail_config = SendGrid::Personalization.new
  mail_config.add_to SendGrid::Email.new(email: user_email)
  mail_config.add_cc SendGrid::Email.new(email: instructor_email) if instructor_email

  mail.add_personalization(mail_config)

  mail.add_content SendGrid::Content.new(type: 'text/plain', value: <<~EMAIL
    Hi #{user_email},

    Thanks for taking our course!

    Your score is #{ user_score }/#{ max_score }
    
    Your score details are below.

    If you have any questions, please contact your instructor at #{ instructor_email }

    #{ grader_result[:summary] }
  EMAIL
  )

  lab_control.update_control_data({ "metadata" => { "lab_score" => user_score }})

  sg_client = SendGrid::API.new(api_key: sendgrid_key)
  sg_response = sg_client.client.mail._('send').post(request_body: mail.to_json)


  if lti_json = control_data.dig('sensitive_metadata', 'lti_payload')
    puts 'Reporting score to LMS...'

    lti_data = JSON.parse(lti_json)
    
    sourcedid = lti_data['lis_result_sourcedid']
    service_url = lti_data['lis_outcome_service_url']
    
    assessment = Assessment.new(
      oauth_consumer_key: lti_key, 
      oauth_secret: lti_secret,
      lis_result_sourcedid: sourcedid,
      lis_outcome_service_url: service_url
    )
    
    assessment.set_value(user_score / max_score)
  end
end

puts "Destroying lab resources..."

TerraformHelper.new(
  dir: '/script/terraform/lab',
  output_attribute: 'tf_lab_destroy_output',
  env: {
    ARM_SUBSCRIPTION_ID: subscription_id,
    ARM_TENANT_ID: tenant_id,
    ARM_CLIENT_ID: client_id,
    ARM_CLIENT_SECRET: client_secret
  },
  opts: {
    backend_config: {
      storage_account_name: storage_account,
      container_name: container,
      resource_group_name: resource_group,
      key: "#{ lab_id }.tfstate",
      use_azuread_auth: true
    },
    vars: {
      resource_group: resource_group,
      storage_account: storage_account,
      container: container,
      lab_id: lab_id,
      sendgrid_key: sendgrid_key
    }
  }
).destroy