# frozen_string_literal: true

class SitesHelperTest < ActionView::TestCase
  test 'should get new sites' do
    webmock_json_file = "#{Rails.root}/test/helpers/webmock_json_responses/sites_response.json"
    stub_request(:get, 'https://api.stackexchange.com/2.2/sites?filter=!*L1-85AFULD6pPxF&pagesize=1000')
      .to_return(status: 200, body: File.open(webmock_json_file).read, headers: {})

    SitesHelper.update_sites
  end
end
