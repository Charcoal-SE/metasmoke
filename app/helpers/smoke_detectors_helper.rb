# frozen_string_literal: true

module SmokeDetectorsHelper
  def self.escape_markdown(s)
    %w{[ ] * _ `}.each do |token|
      s = s.gsub token, '\\' + token
    end
    s
  end
end
