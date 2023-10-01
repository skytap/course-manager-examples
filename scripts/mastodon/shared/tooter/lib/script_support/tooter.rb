require 'lab_control'
require 'http'
require 'json'

HOSTS_FILE = '/etc/hosts'.freeze

class Tooter
  def initialize(content_types: %{ en es esbot })
    @lab_control = LabControl.get
    @users_json = @lab_control.find_metadata_attr('mastodon_users')
    @mast_fqdn = @lab_control.find_metadata_attr('lab_fqdn')
    @mast_ip = @lab_control.find_metadata_attr('mastodon_server_ip')
    @content_types = content_types
    abort 'User accounts not yet created' unless @users_json
    update_hosts_file
  end

  def update_hosts_file
    new_line = "#{@mast_ip} #{@mast_fqdn}\n"

    unless File.read(HOSTS_FILE).include?(new_line)
      open(HOSTS_FILE, 'a') {|f| f.puts(new_line)}
    end
  end

  def content
    @content ||= @content_types.each_with_object({}) do |ctype, hash|
      file = File.read("/script/lib/script_support/toots/#{ ctype }.txt")
      hash[ctype] = file.split("\n").shuffle
    end
  end

  def users
    @users ||= JSON.parse(@users_json)
  end

  def toot
    ctype = @content_types.sample
    post = content[ctype].shift
    user = users[ctype].sample
    response = HTTP.headers(
      Authorization: "Bearer #{ user['token'] }"
    ).post("https://#{ @mast_fqdn }/api/v1/statuses", 
      json: {
        status: post,
        language: ctype[0,2]
      }
    )

    unless response.status.success?
      puts response.body.to_s
      abort 'The status could not be created' 
    end
  end
end