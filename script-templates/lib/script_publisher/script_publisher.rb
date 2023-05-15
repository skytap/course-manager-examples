require "active_support/core_ext/hash/keys"
require "rest-client"
require "digest"
require "base64"
require "json"
require "httplog"
require_relative "package_zipper"

class ScriptPublisher
  POLL_SLEEP_SECS = 5
  MAX_POLLS = 20

  attr_reader :course_id, :script_name, :app_hostname, :api_key, :api_secret

  def initialize(course_id:, script_name:, app_hostname:, api_key:, api_secret:)
    @course_id = course_id
    @script_name = script_name
    @app_hostname = app_hostname
    @api_key = api_key
    @api_secret = api_secret

    HttpLog.configure {|c| c.enabled = !!ENV['VERBOSE'] }
  end

  def publish
    puts "Creating script package..."
    PackageZipper.new(source_dir:, package_path:).zip!

    puts "Creating remote script object..."
    script_object = request(
      method: :post,
      url: scripts_url,
      payload: {
        filename: package_filename,
        byte_size: package_size,
        checksum: package_md5,
        content_type: "application/zip"
      }
    )

    puts "Uploading script package..."
    RestClient.put(
      script_object.dig('direct_upload', 'url'),
      File.open(package_path),
      {
        "Accept" => "application/json",
        "Content-Type" => "application/zip",
        "Content-MD5" => package_md5,
        "Content-Length" => package_size,
        "x-ms-blob-type" => 'BlockBlob'
      }
    )

    script_url = "#{scripts_url}/#{script_object['id']}"

    puts "Notifying server that upload is complete..."
    request(
      method: :put,
      url: script_url,
      payload: { uploaded: true }
    )
  
    print "Waiting for upload to be processed..."
    MAX_POLLS.times do
      request(url: script_url)
      puts "done!"
      return
    rescue RestClient::NotFound
      print "."
      sleep POLL_SLEEP_SECS
    end

    abort "Upload not processed! Please check the logs for further information."
  rescue RestClient::NotFound
    abort "Course not found"
  rescue RestClient::Unauthorized
    abort "API credentials not valid"
  end

  private

  def request(method: :get, url:, payload: nil)
    res = RestClient::Request.execute(
      method:,
      url:,
      payload: payload&.to_json,
      headers: { 
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "Authorization" => authorization
      }
    )

    JSON.parse(res.body) rescue nil
  end

  def authorization
    "Basic " + Base64.strict_encode64("#{api_key}:#{api_secret}")
  end

  def source_dir
    Dir.pwd
  end

  def package_filename
    "#{script_name}.zip"
  end

  def package_path
    File.join("/tmp", package_filename)
  end

  def package_size
    File.size(package_path)
  end

  def package_md5
    Base64.strict_encode64(
      Digest::MD5.hexdigest(
        File.read(package_path)
      ).scan(/../).map { |x| x.hex.chr }.join
    )
  end

  def scripts_url
    "https://#{app_hostname}/api/v1/courses/#{course_id}/scripts"
  end
end