# frozen_string_literal: true

class UserSiteSetting < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :sites

  validate :site_count

  private

  def site_count
    errors.add(:sites, 'must contain at least one site') if sites.blank?
  end
end
