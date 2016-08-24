class ApiToken < ApplicationRecord
  belongs_to :api_key
  belongs_to :user
end
