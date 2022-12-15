require "net/http"
require "json"

METADATA_ADDRESS = "http://169.254.169.254/skytap"

STUB_METADATA_FILE_PATH = File.join(File.dirname(__FILE__), "stub_data/metadata_sample.json")
STUB_CONTROL_DATA_FILE_PATH = File.join(File.dirname(__FILE__), "stub_data/control_data_sample.json")

class BaseMetadata
  class OperationFailedError < StandardError; end

  def metadata
    JSON.parse(metadata_json)
  end

  def user_data
    JSON.parse(metadata["user_data"])
  end

  def configuration_user_data
    JSON.parse(metadata["configuration_user_data"])
  end

  def control_data
    JSON.parse(control_data_json)
  end

  def update_control_data(data)
    control_uri = URI(control_url)
    host, port, path = control_uri.host, control_uri.port, control_uri.path

    http = Net::HTTP.new(host, port)
    http.use_ssl = true if control_uri.instance_of?(URI::HTTPS)
    
    req = Net::HTTP::Put.new(path)
    req.body = data.to_json
    req["Content-Type"] = "application/json"
    
    result = http.request(req)
    
    if result.code == "200"
      @control_data_json = result.body
    else
      raise OperationFailedError, "#{result.code} #{result.message}"
    end
  end

  private

  def metadata_json
    @metadata_json ||= Net::HTTP.get(URI(METADATA_ADDRESS))
  end

  def control_data_json
    @control_data_json ||= Net::HTTP.get(URI(user_data["control_url"]))
  end
end

class StubbedMetadata < BaseMetadata
  def update_control_data(data)
    @control_data_json = JSON.parse(@control_data_json).merge(JSON.merge(data.to_json)).to_json
  rescue
    raise OperationalFailedError, "Invalid data"
  end

  private

  def metadata_json
    @metadata_json ||= File.read(STUB_METADATA_FILE_PATH)
  end

  def control_data_json
    @control_data_json ||= File.read(File.join(File.dirname(__FILE__), "stub_data/control_data_sample.json"))
  end
end

Metadata =
  if (Net::HTTP.start(URI(METADATA_ADDRESS).hostname, URI(METADATA_ADDRESS).port, {open_timeout: 1}) rescue nil)
    BaseMetadata
  elsif File.exist?(STUB_CONTROL_DATA_FILE_PATH) && File.exist?(STUB_METADATA_FILE_PATH)
    STDERR.puts "Using stubbed metadata"
    StubbedMetadata
  else
    raise OperationFailedError, "No metadata source available"
  end