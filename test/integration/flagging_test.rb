require 'test_helper'

class FlaggingTest < ActionDispatch::IntegrationTest
  def setup
    # Use a user with flagging enabled and permissive settings

    @api_token = SecureRandom.uuid

    @user = User.first
    @user.flags_enabled = true
    @user.api_token = @api_token
    @user.save!

    @user.user_site_settings.destroy_all

    site_setting = @user.user_site_settings.new(max_flags: 100)
    site_setting.sites = Site.mains
    site_setting.save!

    # Webmock setup

    webmock_file = "#{Rails.root}/test/integration/webmock_json_responses/mod_sites_response.json"
    stub_request(:get, /https:\/\/api.stackexchange.com\/2\.2\/me\/associated/).
      to_return(:status => 200, :body => File.open(webmock_file).read(), :headers => {})
  end

  test "should update moderator sites" do
    @user.moderator_sites.destroy_all
    assert_equal @user.moderator_sites.count, 0

    @user.update_moderator_sites
    assert_equal @user.moderator_sites.count, 3

    previous_ids = @user.moderator_site_ids
    @user.update_moderator_sites
    assert_equal previous_ids.sort, @user.moderator_site_ids.sort
  end
end
