require "sinatra/base"

class MetadataStubServer < Sinatra::Base
  attr_accessor :control_data_json, :metadata_json, :lab_url, :control_url, :broadcast_url

  def initialize(*args)
    self.control_data_json = File.read(File.join(File.dirname(__FILE__), "control_data.json"))
    self.metadata_json = File.read(File.join(File.dirname(__FILE__), "metadata.json.erb"))

    self.lab_url = ENV['CM_LAB_URL'] || "http://gw/lab_access/self_learner/1/111"
    self.control_url = ENV['CM_CONTROL_URL'] || URI.join(lab_url, "control/1/111").to_s
    self.broadcast_url = ENV['CM_BROADCAST_URL'] || URI.join(lab_url, "learning_console/broadcast").to_s
    super
  end

  before { content_type "application/json" }

  get '/skytap' do
    ERB.new(metadata_json).result(binding)
  end

  get control_url do
    control_data_json
  end

  put control_url do
    body = JSON.parse(request.body.read) rescue {}
    if integration_data = body["integration_data"]
      self.control_data_json = JSON.parse(control_data_json).tap do |h|
        h["integration_data"] = integration_data
      end.to_json
    end

    control_data_json
  end

  post broadcast_url do
    "{}"
  end
end