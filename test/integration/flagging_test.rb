# frozen_string_literal: true

require 'test_helper'

class FlaggingTest < ActionDispatch::IntegrationTest
  def setup
    # Use a user with flagging enabled and permissive settings

    @user = User.first
    setup_user_with_permissive_flag_settings(@user)

    # Pick a couple of random main sites

    @site = Site.mains.where(max_flags_per_post: 3).order('RAND()').last
    @limited_site = Site.mains.where(max_flags_per_post: 1).order('RAND()').last

    setup_posts
    setup_webmock
  end

  def setup_posts
    # Post setup

    @stack_id = 1234
    @multi_rev_stack_id = 4321

    Reason.update_all(weight: 10)

    common_attrs = {
      site: @site,
      reasons: Reason.last(2),
      user_reputation: 1,
      stack_exchange_user: StackExchangeUser.new(username: 'asdf',
                                                 reputation: 1,
                                                 site: @site)
    }

    @post = Post.create({
      link: "//#{@site.site_domain}/questions/#{@stack_id}"
    }.reverse_merge!(common_attrs))

    @multi_rev_post = Post.create({
      link: "//#{@site.site_domain}/questions/#{@multi_rev_stack_id}"
    }.reverse_merge!(common_attrs))

    @limited_post = Post.create({
      link: "//#{@limited_site.site_domain}/questions/#{@stack_id}",
      site: @limited_site,
      stack_exchange_user: StackExchangeUser.new(username: 'asdf',
                                                 reputation: 1,
                                                 site: @limited_site)
    }.reverse_merge!(common_attrs))
  end

  def setup_webmock
    WebMock.reset!

    stub_request(:get, %r{https://api.stackexchange.com/2\.2/me/associated})
      .to_return(status: 200, body: webmock_file('mod_sites_response'), headers: {})

    @single_rev_stub = stub_request(:get, %r{https://api.stackexchange.com/2\.2/posts/#{@stack_id}/revisions})
                       .to_return(status: 200, body: webmock_file('single_revision_response'), headers: {})

    @multi_rev_stub = stub_request(:get, %r{https://api.stackexchange.com/2\.2/posts/#{@multi_rev_stack_id}/revisions})
                      .to_return(status: 200, body: webmock_file('multi_revision_response'), headers: {})

    @flag_options_stub = stub_request(:get, %r{https://api.stackexchange.com/2\.2/(questions|answers)/\d+/flags/options})
                         .to_return(status: 200, body: webmock_file('flag_options_response'), headers: {})

    @flag_submit_stub = stub_request(:post, %r{https://api.stackexchange.com/2\.2/(questions|answers)/\d+/flags/add})
                        .to_return(status: 200, body: webmock_file('flag_submit_response'), headers: {})
  end

  def webmock_file(name)
    File.open("#{Rails.root}/test/integration/webmock_json_responses/#{name}.json").read
  end

  def setup_user_with_permissive_flag_settings(user)
    user.flags_enabled = true
    user.encrypted_api_token = SecureRandom.uuid
    user.save!

    user.add_role :core

    user.user_site_settings.destroy_all

    site_setting = user.user_site_settings.new(max_flags: 100)
    site_setting.sites = Site.mains
    site_setting.save!

    flag_condition = user.flag_conditions.new(min_weight: 10,
                                              max_poster_rep: 1,
                                              min_reason_count: 1,
                                              sites: Site.mains)

    # Ignore any flag accuracy warnings; we're not concerned about them right now
    flag_condition.save(validate: false)
  end

  test 'should update moderator sites' do
    @user.moderator_sites.destroy_all
    assert_equal 0, @user.moderator_sites.count

    @user.update_moderator_sites
    assert_equal 3, @user.moderator_sites.count

    previous_ids = @user.moderator_site_ids
    @user.update_moderator_sites
    assert_equal previous_ids.sort, @user.moderator_site_ids.sort
  end

  test 'should refuse to flag on a site user is a moderator on' do
    @user.moderator_sites.create(site: Site.first)

    assert_raise do
      @user.spam_flag(Post.new(site: Site.first))
    end
  end

  test 'should refuse to flag if user has no access token' do
    @user.api_token = nil

    assert_raise do
      @user.spam_flag(Post.new)
    end
  end

  test 'should set revision count' do
    @post.get_revision_count

    assert_requested @single_rev_stub
    assert_equal 1, @post.revision_count

    @multi_rev_post.get_revision_count

    assert_requested @multi_rev_stub
    assert_operator @multi_rev_post.revision_count, :>, 1
  end

  test "shouldn't flag if flagging is disabled" do
    FlagSetting.find_by(name: 'flagging_enabled').update(value: '0')
    assert_equal 'Flagging disabled', @post.autoflag
  end

  test "shouldn't flag if there are no eligible users" do
    User.update_all(flags_enabled: false)

    assert_equal 'No users eligible to flag', @post.autoflag
  end

  test 'should request revision count' do
    @post.autoflag

    assert_requested @single_rev_stub
  end

  test "shouldn't flag if post has more than one revision" do
    assert_equal 'More than one revision', @multi_rev_post.autoflag
  end

  test 'should flag flaggable post' do
    @post.autoflag

    assert_requested @flag_options_stub, at_least_times: 1
    assert_requested @flag_submit_stub, at_least_times: 1
  end

  test "shouldn't flag if post doesn't have enough weight" do
    Reason.update_all(weight: 1)

    @post.reload.autoflag

    assert_not_requested @flag_submit_stub
  end

  test "shouldn't flag if user has too much rep" do
    @post.stack_exchange_user.reputation = 100_000

    @post.autoflag

    assert_not_requested @flag_submit_stub
  end

  test 'should cast only three flags on flaggable post' do
    10.times do
      user = @user.dup
      user.email = SecureRandom.hex
      user.save!(validate: false)

      setup_user_with_permissive_flag_settings(user)
    end

    @post.autoflag
    assert_requested @flag_submit_stub, times: 3
  end

  test 'should cast only one flag on flaggable post on limited site' do
    10.times do
      user = @user.dup
      user.email = SecureRandom.hex
      user.save!(validate: false)

      setup_user_with_permissive_flag_settings(user)
    end

    @limited_post.autoflag
    assert_requested @flag_submit_stub, times: 1
  end

  test 'should respect max flags setting' do
    10.times do
      user = @user.dup
      user.email = SecureRandom.hex
      user.save!(validate: false)

      setup_user_with_permissive_flag_settings(user)
    end

    FlagSetting.find_by(name: 'max_flags').update(value: '2')

    @post.autoflag
    assert_requested @flag_submit_stub, times: 2
  end

  test 'should respect dry run setting' do
    FlagSetting.find_by(name: 'dry_run').update(value: '1')

    @post.autoflag
    assert_requested @flag_options_stub, at_least_times: 1
    assert_not_requested @flag_submit_stub
  end
end
