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
      regex_support = {
        '\w' => '[a-zA-Z0-9_]',
        '\W' => '[^a-zA-Z0-9_]',
        '\s' => '[\r\n\t\f\v ]',
        '\S' => '[^\r\n\t\f\v ]',
        '\d' => '[0-9]',
        '\D' => '[^0-9]'
      }
      regex_support.each { |k, v| input = input.gsub(k, v) }
    else
      operation = 'LIKE'
      input = '%' + ActiveRecord::Base.sanitize_sql_like(input) + '%'
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
