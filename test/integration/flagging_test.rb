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

    # Pick a couple of random main sites

    @site = Site.mains.where(max_flags_per_post: 3).order("RAND()").last
    @limited_site = Site.mains.where(max_flags_per_post: 1).order("RAND()").last

    # Post setup

    @stack_id = 1234
    @multi_rev_stack_id = 4321

    @post = Post.new({
      link: "//#{@site.site_domain}/questions/#{@stack_id}",
      site: @site
    })

    @multi_rev_post = Post.new({
      link: "//#{@site.site_domain}/questions/#{@multi_rev_stack_id}",
      site: @site
    })

    @limited_post = Post.new({
      link: "//#{@limited_site.site_domain}/questions/#{@stack_id}",
      site: @limited_site
    })

    setup_webmock
  end

  def setup_webmock
    stub_request(:get, /https:\/\/api.stackexchange.com\/2\.2\/me\/associated/).
      to_return(:status => 200, :body => webmock_file("mod_sites_response"), :headers => {})

    @single_rev_stub = stub_request(:get, /https:\/\/api.stackexchange.com\/2\.2\/posts\/#{@stack_id}\/revisions/).
      to_return(status: 200, body: webmock_file("single_revision_response"), headers: {})

    @multi_rev_stub = stub_request(:get, /https:\/\/api.stackexchange.com\/2\.2\/posts\/#{@multi_rev_stack_id}\/revisions/).
      to_return(status: 200, body: webmock_file("multi_revision_response"), headers: {})
  end

  def webmock_file(name)
    File.open("#{Rails.root}/test/integration/webmock_json_responses/#{name}.json").read()
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

  test "should refuse to flag on a site user is a moderator on" do
    @user.moderator_sites.create(site: Site.first)

    assert_raise do
      @user.spam_flag(Post.new(site: Site.first))
    end
  end

  test "should refuse to flag if user has no access token" do
    @user.api_token = nil

    assert_raise do
      @user.spam_flag(Post.new)
    end
  end

  test "should set revision count" do
    @post.get_revision_count

    assert_requested @single_rev_stub
    assert_equal @post.revision_count, 1

    @multi_rev_post.get_revision_count

    assert_requested @multi_rev_stub
    assert_operator @multi_rev_post.revision_count, :>, 1
  end
end
