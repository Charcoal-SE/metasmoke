# frozen_string_literal: true

module AuthenticationHelper
  def auth_url(scope, redirect_uri)
    config = AppConfig['stack_exchange']
    "https://stackexchange.com/oauth?client_id=#{config['client_id']}&scope=#{scope}&redirect_uri=#{redirect_uri}"
  end

  def write_auth_url
    config = AppConfig['token_store']
    state = Rails.cache.fetch("token_migration_state/#{current_user.id}", expires_in: 30.minutes) do
      SecureRandom.hex(10)
    end
    "#{config['host']}/auth?state=#{state}"
  end

  def identify_auth_url
    config = AppConfig['stack_exchange']
    auth_url('', config['redirect_uri'])
  end

  def login_auth_url
    config = AppConfig['stack_exchange']
    auth_url('', config['login_redirect_uri'])
  end

  def signup_auth_url
    login_auth_url
  end

  def access_token_from_code(_code, redirect_uri = AppConfig['stack_exchange']['redirect_uri'])
    config = AppConfig['stack_exchange']

    request_params = {
      client_id: config['client_id'],
      client_secret: config['client_secret'],
      code: params[:code],
      redirect_uri: redirect_uri
    }.stringify_keys
    response = Rack::Utils.parse_nested_query(Net::HTTP.post_form(
      URI.parse('https://stackexchange.com/oauth/access_token'), request_params
    ).body)

    response['access_token']
  end

  def info_for_access_token(access_token)
    config = AppConfig['stack_exchange']
    response = open("https://api.stackexchange.com/2.2/access-tokens/#{access_token}?key=#{config['key']}").read
    begin
      JSON.parse(response)['items'][0]
    rescue OpenURI::HTTPError
      ap response
      raise
    end
  end
end
