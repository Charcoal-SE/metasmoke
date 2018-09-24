# frozen_string_literal: true

class DomainLink < ApplicationRecord
  include Websocket

  belongs_to :left, class_name: 'SpamDomain'
  belongs_to :right, class_name: 'SpamDomain'
  belongs_to :creator, class_name: 'User'

  def self.link_types
    Rails.cache.fetch :domain_link_types do
      DomainLink.select(Arel.sql('DISTINCT link_type')).map(&:link_type)
    end
  end
end
