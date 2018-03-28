# frozen_string_literal: true

module SearchHelper
  def self.parse_search_params(params, symbol, user_signed_in)
    input = params[symbol] || ''

    if params[is_regex?(symbol)]
      operation = if user_signed_in
                    params[is_inverse_regex?(symbol)] ? 'NOT REGEXP' : 'REGEXP'
                  else
                    false
                  end
      regex_support = {
        '\w' => '[a-zA-Z0-9_]',
        '\W' => '[^a-zA-Z0-9_]'
      }
      regex_support.each { |k, v| input = input.gsub(k, v) }
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
