# frozen_string_literal: true

module SearchHelper
  def self.parse_search_params(params, symbol, user_signed_in)
    input = params[symbol] || ''

    if user_signed_in && params[is_regex?(symbol)]
      operation = params[is_inverse_regex?(symbol)] ? 'NOT REGEXP' : 'REGEXP'
    else
      operation = 'LIKE'
      input = '%' + input + '%'
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
