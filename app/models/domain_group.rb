# frozen_string_literal: true

class DomainGroup < ApplicationRecord
  has_and_belongs_to_many :spam_domains

  def preference_ref_name
    name
  end
end
