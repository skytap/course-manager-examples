require "rest-client"
require "mime/types"
require "hashie/mash"
require "base64"
require "json"
require "httplog"
require "slop"
require "active_support/core_ext/object/blank"

class ManualPublisher
  POLL_SLEEP_SECS = 5
  MAX_POLLS = 20

  attr_reader :course_id, :attachment_dir, :html_file, :api_hostname, :api_token, :api_secret

  def initialize(course_id:, attachment_dir:, html_file:, api_hostname:, api_token:, api_secret:, verbose: false)
    @course_id = course_id
    @attachment_dir = attachment_dir
    @html_file = html_file
    @api_hostname = api_hostname
    @api_token = api_token
    @api_secret = api_secret

    HttpLog.configure {|c| c.enabled = !!verbose }
  end

  def publish
    puts "Deleting old draft..."
    request(method: :delete)

    puts "Uploading content..."
    request(
      method: :put,
      payload: {
        status: "content_complete",
        content:,
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
  end

  private

  def upload_attachments
    request.attachment_upload_data.each do |uploadable|
      next unless uploadable.blob_upload_url

      file_info = initial_attachment_upload_data_for(uploadable.file_path)
      RestClient.put(
        uploadable.blob_upload_url,
        File.open(uploadable.file_path),
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
      current_state = request&.state

      if desired_state == current_state
        puts "Now #{current_state}"
        return
      elsif failure_state == current_state
        raise "Failure state of #{current_state} occurred"
      else
        puts "Currently #{current_state}, waiting for #{desired_state}"
        sleep POLL_SLEEP_SECS
      end
    end

    raise "Timed out waiting for #{desired_state}"
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

    unless r.body.blank?
      Hashie::Mash.new(JSON.parse(r.body))
    end
  rescue RestClient::NotFound
    STDERR.puts "Error: Course ID not valid"
    raise
  rescue RestClient::Unauthorized
    STDERR.puts "Error: API credentials not valid"
    raise
  rescue RestClient::Locked
    STDERR.puts "Error: Manual is locked, please wait a few moments and try again"
    raise
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
      file_path: f,
      checksum: Base64.strict_encode64(
                  Digest::MD5.hexdigest(
                    File.read(f)
                  ).scan(/../).map { |x| x.hex.chr }.join
                ),
      content_type: ( MIME::Types.type_for(f).first&.content_type || 
                        raise("Can't find content-type for #{f}") )
    }
  end

  def content
    File.read(html_file)
  end

  def url
    "https://#{api_hostname}/api/v1/courses/#{course_id}/course_manual/versions/draft"
  end

  def authorization
    "Basic " + Base64.strict_encode64("#{api_token}:#{api_secret}")
  end
end

begin
  options = Slop.parse do |o|
    o.string "--api_hostname", "Course Manager API hostname (e.g. customername.skytap-portal.com)", required: true
    o.string "--api_token", "Course Manager API token", required: true
    o.string "--api_secret", "Course Manager API secret", required: true
    o.int "--course_id", "Course ID for which the manual is being published", required: true
    o.string "--attachment_dir", "Relative path of the directory containing your attachments"
    o.string "--html_file", "HTML file containing the manual content", required: true
    o.boolean "-v", "--verbose", "Enable verbose mode", default: false
    o.on "-h", "--help" do
      puts o
      exit 1
    end    
  end
rescue Slop::Error => e
  puts "#{e} (try --help)"
  exit 1
end

ManualPublisher.new(**options.to_hash).publish