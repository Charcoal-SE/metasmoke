# frozen_string_literal: true

module SearchHelper
  def self.parse_search_params(params, symbol, user)
    input = params[symbol] || ''

    if params[is_regex?(symbol)]
      operation = if !user.nil? && user.can_use_regex_search?
                    params[is_inverse_regex?(symbol)] ? 'NOT REGEXP' : 'REGEXP'
                  else
                    false
                  end
    else
      operation = 'LIKE'
      input = "%#{ActiveRecord::Base.sanitize_sql_like(input)}%" unless input.nil? || input.empty?
    end

    [input, operation]
  end

  def self.is_regex?(symbol) # rubocop:disable Naming/PredicateName
    "#{symbol}_is_regex".to_sym
  end

  def self.is_inverse_regex?(symbol) # rubocop:disable Naming/PredicateName
    "#{symbol}_is_inverse_regex".to_sym
  end
end
