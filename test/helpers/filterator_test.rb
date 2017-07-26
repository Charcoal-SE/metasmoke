# frozen_string_literal: true

class FilteratorTest < ActionView::TestCase
  test 'string_from_fields' do
    broad = Filterator.string_from_fields([
                                            'api_keys.id',
                                            'api_tokens.code',
                                            'blacklisted_websites.is_active',
                                            'commit_statuses.commit_message',
                                            'deletion_logs.updated_at',
                                            'feedbacks.post_id',
                                            'flags.post_id',
                                            'ignored_users.id',
                                            'posts.title',
                                            'posts_reasons.reason_id',
                                            'reasons.reason_name',
                                            'roles.resource_type',
                                            'sites.site_logo',
                                            'smoke_detectors.access_token',
                                            'stack_exchange_users.answer_count',
                                            'users.id',
                                            'users_roles.role_id',
                                            'moderator_sites.site_id'
                                          ])
    assert_equal "gIBBAQQAAYEAAEhAgIBBAgQ=\n", broad

    narrow = Filterator.string_from_fields(['posts.id', 'posts.title', 'posts.body', 'posts.link', 'posts.site_id'])
    assert_equal "AAAAAAAAAAPEAAAAAAAAAAA=\n", narrow

    none = Filterator.string_from_fields([])
    assert_equal "AAAAAAAAAAAAAAAAAAAAAAA=\n", none
  end
end
