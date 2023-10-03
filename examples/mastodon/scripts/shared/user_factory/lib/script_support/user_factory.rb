require "skytap_metadata"
require "lab_control"
require 'server_tools'
require 'faker'

ALLOWED_NAMES = /^[A-Za-z ]+$/

class UserFactory
  def initialize
    @lab_control = LabControl.get
    @control_data = @lab_control.control_data
    mast_ip = @lab_control.find_metadata_attr('mastodon_server_ip')
    mastodon_server_username = @lab_control.find_metadata_attr('mastodon_server_username')
    mastodon_server_password = @lab_control.find_metadata_attr('mastodon_server_password')
    @mast_manager = MastodonServerManager.new(mast_ip, mastodon_server_username, mastodon_server_password)
  end

  def create_user(username: nil, email: nil, password: nil, display_name: nil, is_admin: false)
    until ALLOWED_NAMES.match?(display_name)
      display_name = "#{ Faker::Name.first_name } #{ Faker::Name.last_name }"
    end

    @mast_manager.setup_user_and_token(display_name:, is_admin:,
      email: email || Faker::Internet.email(name: display_name),
      password: Faker::Internet.password(min_length: 10),
      username: Faker::Internet.username(specifier: display_name, separators: ['_']),
    )
  end
end



