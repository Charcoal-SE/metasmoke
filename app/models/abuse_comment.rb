# frozen_string_literal: true

class AbuseComment < ApplicationRecord
  include Websocket

  belongs_to :user
  belongs_to :report, class_name: 'AbuseReport', foreign_key: 'abuse_report_id'
end
