module SafeStoreLocation
  MAX_LOCATION_SIZE = ActionDispatch::Cookies::MAX_COOKIE_SIZE / 2

  def store_location_for(resource_or_scope, location)
    super unless location && location.size > MAX_LOCATION_SIZE
  end
end

Devise::FailureApp.include SafeStoreLocation
