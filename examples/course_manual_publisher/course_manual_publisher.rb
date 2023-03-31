require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/blank"
require "base64"
require "hashie/mash"
require "httplog"
require "json"
require "mime/types"
require "nokogiri"
require "rest-client"
require "pry"
class CourseManualPublisher
  class UnexpectedStateError < StandardError; end

  POLL_SLEEP_SECS = 5
  MAX_POLLS = 20

  attr_reader :course_id, :attachment_dir, :html_file, :app_hostname, :api_key, :api_secret

  def initialize(course_id:, attachment_dir:, html_file:, app_hostname:, api_key:, api_secret:)
    @course_id = course_id
    @app_hostname = app_hostname
    @api_key = api_key
    @api_secret = api_secret

    @html_file = File.expand_path(html_file)
    unless File.exist?(@html_file)
      die("HTML file not found")
    end

    @attachment_dir = normalize_relative_path(attachment_dir.presence || ".")
    unless Dir.exist?(File.expand_path(File.dirname(@html_file), @attachment_dir))
      die("Attachment dir not found")
    end

    HttpLog.configure {|c| c.enabled = !!ENV['VERBOSE'] }
  end

  def publish
    puts "Deleting old draft..."
    request(method: :delete)

    puts "Uploading content..."
    request(
      method: :put,
      payload: {
        status: "content_complete",
        content: normalized_html,
        attachment_upload_data: initial_attachment_upload_data&.to_json
      }
    )

    if initial_attachment_upload_data
      poll_for_state "needs_attachments", "draft"

      puts "Uploading attachments..."
      upload_attachments
    end

    request(method: :put, payload: { status: "ready_to_process" })
    poll_for_state "ready_to_publish", "needs_attachments"

    puts "Marking as published..."
    request(method: :put, payload: { status: "published" })

    puts "Done."
  rescue UnexpectedStateError => e
    die e.message
  rescue RestClient::NotFound
    die "Course ID not valid"
  rescue RestClient::Unauthorized
    die "API credentials not valid"
  rescue RestClient::Locked
    die "Manual is locked, please wait a few moments and try again"
  end

  private

  def upload_attachments
    request['attachment_upload_data'].each do |uploadable|
      next unless uploadable['blob_upload_url']

      file_info = initial_attachment_upload_data_for(uploadable['file_path'])
      RestClient.put(
        uploadable['blob_upload_url'],
        File.open(uploadable['file_path']),
        {
          "Accept" => "application/json",
          "Content-Type" => file_info[:content_type],
          "Content-MD5" => file_info[:checksum],
          "Content-Length" => file_info[:byte_size],
          "x-ms-blob-type" => 'BlockBlob'
        }
      )
    end
  end

  def poll_for_state(desired_state, failure_state)
    1.upto(MAX_POLLS) do
      current_state = request['state']

      if desired_state == current_state
        puts "Now #{current_state}"
        return
      elsif failure_state == current_state
        raise UnexpectedStateError, "Failure state of #{current_state} occurred"
      else
        puts "Currently #{current_state}, waiting for #{desired_state}"
        sleep POLL_SLEEP_SECS
      end
    end

    raise UnexpectedStateError, "Timed out waiting for #{desired_state}"
  end

  def request(method: :get, payload: nil)
    r = RestClient::Request.execute(
      method:,
      url:,
      payload: payload&.to_json,
      headers: { 
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "Authorization" => authorization
      }
    )

    JSON.parse(r.body) if r.body.present?
  end

  def initial_attachment_upload_data
    return nil unless Dir.exist?(attachment_dir.to_s)

    Dir.glob(File.join(attachment_dir, "*")).map do |f|
      initial_attachment_upload_data_for(f)
    end.presence
  end

  def initial_attachment_upload_data_for(f)
    {
      filename: File.basename(f),
      byte_size: File.size(f),
      file_path: normalize_relative_path(f),
      checksum: checksum_for(f),
      content_type: ( content_type_for(f) ||
                        raise("Can't find content-type for #{f}") )
    }
  end

  def html
    File.read(html_file)
  end

  def normalized_html
    normalize_relative_paths_in_html(html)
  end

  def url
    "https://#{app_hostname}/api/v1/courses/#{course_id}/course_manual/versions/draft"
  end

  def authorization
    "Basic " + Base64.strict_encode64("#{api_key}:#{api_secret}")
  end

  def checksum_for(file)
    Base64.strict_encode64(
      Digest::MD5.hexdigest(
        File.read(file)
      ).scan(/../).map { |x| x.hex.chr }.join
    )
  end

  def content_type_for(file)
    MIME::Types.type_for(file).first&.content_type
  end

  def normalize_relative_paths_in_html(html)
    Nokogiri::HTML(html).tap do |doc|
      doc.search('a[href]').each { |l| l['href'] = normalize_relative_path(l['href']) }
      doc.search('img[src]').each { |i| i['src'] = normalize_relative_path(i['src']) }
    end.to_s
  end

  def normalize_relative_path(path)
    if path.start_with?("/")
      raise ArgumentError, "relative path required"
    end

    path.gsub("\\","/").delete_prefix("./")
  end

  def die(msg)
    STDERR.puts msg
    exit 1
  end
end