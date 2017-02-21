module AuthenticationHelper
  def write_auth_url
    config = AppConfig["stack_exchange"]
    "https://stackexchange.com/oauth?client_id=#{config["client_id"]}&scope=write_access,no_expiry&redirect_uri=#{config["redirect_uri"]}"
  end

  def identify_auth_url
    config = AppConfig["stack_exchange"]
    "https://stackexchange.com/oauth?client_id=#{config["client_id"]}&scope=&redirect_uri=#{config["redirect_uri"]}"
  end

  def login_auth_url
    identify_auth_url
  end

  def signup_auth_url
    login_auth_url
  end
end
