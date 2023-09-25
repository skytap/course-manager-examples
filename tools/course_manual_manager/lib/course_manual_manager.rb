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

require "active_support/core_ext/array/wrap"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/object/try"
require "active_support/core_ext/string/inflections"
require "base64"
require "digest/md5"
require "httplog"
require "json"
require "mime/types"
require "nokogiri"
require "rest-client"

class CourseManualManager
  class NoContentError < StandardError; end
  class UnexpectedStateError < StandardError; end

  POLL_SLEEP_SECS = 5
  MAX_POLLS = 20

  attr_reader :course_id, :html_file, :app_hostname, :api_key, :api_secret, :base_dir,
              :deleting, :uploading, :publishing,
              :doc, :resolved_paths, :resolved_path_aliases,
              :initial_attachment_upload_data, :processed_html

  alias_method :publishing?, :publishing
  alias_method :uploading?, :uploading
  alias_method :deleting?, :deleting

  def initialize( course_id:, html_file:, app_hostname:, api_key:, api_secret:,
                  delete: true, upload: true, publish: true )
    @course_id = course_id
    @app_hostname = app_hostname
    @api_key = api_key
    @api_secret = api_secret
    @publishing = publish
    @deleting = delete || upload
    @uploading = upload

    @html_file = File.expand_path(html_file)
    unless File.exist?(@html_file)
      abort "HTML file '#{@html_file}' not found"
    end

    @base_dir = File.dirname(@html_file)

    HttpLog.configure {|c| c.enabled = verbose? }
  end

  def publish
    if deleting?
      puts "Deleting old draft if any..."
      request(method: :delete, payload: { notify_draft_changed: (!uploading? && !publishing?) })
    end

    if uploading?
      puts "Parsing HTML..."
      parse_doc!

      puts "Analyzing HTML to resolve links..."
      resolve_local_paths!

      puts "Processing HTML..."
      process_html!

      puts "Uploading content..."
      upload_content

      if initial_attachment_upload_data.any?
        poll_for_state "needs_attachments", "draft"

        puts "Uploading attachments..."
        upload_attachments

        request(method: :put, payload: { status: "ready_to_process" })
      end

      poll_for_state "ready_to_publish", ["needs_attachments", "draft"]
    end

    if publishing?
      puts "Marking draft as published..."
      begin
        request(method: :put, payload: { status: "published" })
      rescue RestClient::UnprocessableEntity
        abort "No draft to publish!"
      end
    end

    if uploading? && !publishing?
      puts <<~EOF
        To preview content:

        1. Visit https://#{app_hostname}/courses/#{course_id}
        2. Click Course options dropdown > Preview
        3. Select 'Latest draft' as manual content source

      EOF
    end

    puts "Done."
  rescue UnexpectedStateError => e
    abort e.message
  rescue NoContentError
    puts "There are no changes to publish."
  rescue RestClient::NotFound
    abort "Course ID not valid"
  rescue RestClient::Unauthorized
    abort "API credentials not valid"
  rescue RestClient::Locked
    abort "Manual is locked, please wait a few moments and try again"
  end

  private

  def parse_doc!
    @doc = Nokogiri::HTML.parse(raw_html)
  end

  def resolve_local_paths!
    @resolved_paths = {}
    @resolved_path_aliases = {}

    doc.search('a[href], img[src]').each do |tag|
      path = tag['href'] || tag['src']

      if resolved_path = resolve_path_if_local(path)
        if File.exist?(resolved_path)
          puts "Resolved #{path} => #{resolved_path}" if verbose?
          resolved_paths[path] = resolved_path
          resolved_path_aliases[path_alias_for(resolved_path)] = resolved_path
        else
          STDERR.puts "WARNING: resolved #{path} => #{resolved_path}, but matching local file not found"
        end
      else
        puts "Path not resolved to local file: #{path}" if verbose?
      end
    end

    @initial_attachment_upload_data =
      resolved_paths.values.map do |absolute_path|
        {
          filename: File.basename(absolute_path),
          byte_size: File.size(absolute_path),
          file_path: path_alias_for(absolute_path),
          checksum: checksum_for(absolute_path),
          content_type: content_type_for(absolute_path)
        }
      end.uniq {|resolved_path| resolved_path[:checksum]}
  end

  def process_html!
    @processed_html =
      doc.dup.tap do |d|
        d.search('a[href], img[src]').each do |tag|
          attr_name = tag.key?('href') ? 'href' : 'src'
          path = tag[attr_name]
          tag[attr_name] = path_alias_for(resolved_paths[path]) if resolved_paths.key?(path)
        end
      end.to_s
  end

  def path_alias_for(absolute_path)
    "/placeholder/#{checksum_for(absolute_path)}"
  end

  def upload_attachments
    request['attachment_upload_data'].each do |uploadable|
      next unless uploadable['blob_upload_url']

      full_path = resolved_path_aliases[uploadable['file_path']]

      RestClient.put(
        uploadable['blob_upload_url'],
        File.open(full_path),
        {
          "Accept" => "application/json",
          "Content-Type" => content_type_for(full_path),
          "Content-MD5" => checksum_for(full_path),
          "Content-Length" => File.size(full_path),
          "x-ms-blob-type" => 'BlockBlob'
        }
      )
    end
  end

  def upload_content
    request(
      method: :put,
      payload: {
        status: "content_complete",
        content: processed_html,
        attachment_upload_data: initial_attachment_upload_data
      }
    )
  end

  def poll_for_state(desired_states, failure_states)
    desired_states, failure_states =
      Array.wrap(desired_states), Array.wrap(failure_states)

    desired_states_str = desired_states.map(&:humanize).map(&:downcase).join(' or ')

    MAX_POLLS.times do
      current_state = request.try(:[], 'state') ||
                        raise(UnexpectedStateError, "No state found")

      current_state_str = current_state.humanize.downcase

      if desired_states.include?(current_state)
        puts "Now #{current_state_str}"
        return current_state
      elsif failure_states.include?(current_state)
        raise UnexpectedStateError, "Failure: unexpectedly #{current_state_str}"
      else
        puts "Currently #{current_state_str}, waiting until #{desired_states_str}"
        sleep POLL_SLEEP_SECS
      end
    end

    raise UnexpectedStateError, "Timed out waiting until #{desired_states_str}"
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
      },
      verify_ssl: (ENV['IGNORE_SSL_ERRORS'] != '1')
    )
    raise NoContentError if r.code == 204

    JSON.parse(r.body) if r.body.present?
  end

  def raw_html
    File.read(html_file)
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
    MIME::Types.type_for(file).first&.content_type || 
      raise("Can't find content-type for #{f}")
  end

  # Paths are treated as local attachments to be uploaded / relinked in HTML if
  # a) URI format with scheme of 'file' => absolute local path; OR
  # b) non-URI format, doesn't start with / => relative local path (to HTML)
  def resolve_path_if_local(path)
    return nil if path.nil?

    res_path = path.gsub("\\","/")

    if res_path.include?(":")
      if res_path.split(":").first == "file"
        File.expand_path(res_path.gsub(/^file\:\/\/.*?\//, "/") )
      end
    elsif !res_path.start_with?("/")
      File.expand_path(File.join(base_dir, res_path))
    end
  end

  def verbose?
    !!ENV['VERBOSE']
  end
end