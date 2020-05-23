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
      input = if symbol == :body
                ActiveRecord::Base.sanitize_sql_like(input)
              else
                '%' + ActiveRecord::Base.sanitize_sql_like(input) + '%'
              end
    end

    [input, operation]
  end

  def self.is_regex?(symbol) # rubocop:disable Style/PredicateName
    (symbol.to_s + '_is_regex').to_sym
  end

  def self.is_inverse_regex?(symbol) # rubocop:disable Style/PredicateName
    (symbol.to_s + '_is_inverse_regex').to_sym
  end
end
