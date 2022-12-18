require "sinatra/base"
require "pry"
class MetadataStubServer < Sinatra::Base
  attr_accessor :control_data_json, :metadata_json, :control_url

  def initialize(*args)
    self.control_data_json = File.read(File.join(File.dirname(__FILE__), "control_data.json"))
    self.metadata_json = File.read(File.join(File.dirname(__FILE__), "metadata.json.erb"))
    self.control_url = ENV['CONTROL_URL'] || "http://gw/lab_access/self_learner/1/111/control/1/111"
    super
  end

  before { content_type "application/json" }

  get '/skytap' do
    ERB.new(metadata_json).result(binding)
  end

  get "/lab_access/self_learner/1/111/control/1/111" do
    control_data_json
  end

  put "/lab_access/self_learner/1/111/control/1/111" do
    body = JSON.parse(request.body.read) rescue {}
    if integration_data = body["integration_data"]
      self.control_data_json = JSON.parse(control_data_json).tap do |h|
        h["integration_data"] = integration_data
      end.to_json
    end

    control_data_json
  end

  post "/lab_access/self_learner/1/111/learning_console/broadcast" do
    "{}"
  end
end