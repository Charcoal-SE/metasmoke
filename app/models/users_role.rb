# frozen_string_literal: true

class UsersRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
end
