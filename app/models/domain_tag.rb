# frozen_string_literal: true

class DomainTag < ApplicationRecord
  include Websocket

  has_and_belongs_to_many :spam_domains, (-> { uniq })
  has_and_belongs_to_many :posts
  has_many :abuse_reports, as: :reportable
end
