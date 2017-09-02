# frozen_string_literal: true

class SpamDomain < ApplicationRecord
  has_and_belongs_to_many :posts
  has_and_belongs_to_many :domain_tags
end
