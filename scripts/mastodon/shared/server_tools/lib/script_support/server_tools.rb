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

require 'net/ssh'
require 'net/sftp'
require 'securerandom'

module ServerCommandRunner
  def self.run(host, user, password, command)
    Net::SSH.start(host, user, password: password) do |ssh|
      output = ssh.exec!(command)
      return output
    end
  end    
end

class MastodonServerManager
  def initialize(host, user, password)
    @host = host
    @user = user
    @password = password
  end

  def setup_user_and_token(username:, email:, password:, display_name:)
    rails_run(
      "user = User.find_or_initialize_by(email: '#{ email }') do |new_user|",
      "new_user.password = '#{ password }'",
      "new_user.account_attributes = { username: '#{ username }', display_name: '#{ display_name }'}",
      "new_user.bypass_invite_request_check = true",
      "new_user.confirmed_at = Time.now.utc",
      "new_user.save(validate: false); end",
      "app = user.applications.find_or_create_by!(name: '#{ username }', redirect_uri: Doorkeeper.configuration.native_redirect_uri, scopes: 'read write follow')",
      "puts user.token_for_app(app).token"
    ).strip.split("\n").last
  end

  def setup_user(username:, email:, password:, display_name:)
    rails_run(
      "user = User.find_or_initialize_by(email: '#{ email }') do |new_user|",
      "new_user.password = '#{ password }'",
      "new_user.account_attributes = { username: '#{ username }', display_name: '#{ display_name }'}",
      "new_user.bypass_invite_request_check = true",
      "new_user.confirmed_at = Time.now.utc",
      "new_user.save(validate: false); end",
    )
  end
  
  def run(command)
    ServerCommandRunner.run(
      @host,
      @user,
      @password,
      command
    )
  end

  def bundle_exec(command)
    run("sudo docker exec web bundle exec #{ command }")
  end

  def copy_directory_to_server(localdir)
    remotedir = "/home/#{ @user }/#{ SecureRandom.hex(10) }"
    Net::SFTP.start(@host, @user, password: @password) do |sftp|
      sftp.mkdir!(remotedir)
      sftp.upload!(localdir, remotedir)
    end
    return remotedir
  end

  def rails_run(*commands)
    bundle_exec("rails r \"#{ commands.join('; ') }\"")
  end
end
