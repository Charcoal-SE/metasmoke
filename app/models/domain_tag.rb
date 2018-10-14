# frozen_string_literal: true

class DomainTag < ApplicationRecord
  include Websocket

  has_and_belongs_to_many :spam_domains
  has_and_belongs_to_many :posts
  has_many :abuse_reports, as: :reportable

  scope :standard, -> { where(special: false) }
  scope :special, -> { where(special: true) }
end
