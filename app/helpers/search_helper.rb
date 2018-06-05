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
      input = regex_support input
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

  def self.regex_support(text)
    {
      '\w' => '[a-zA-Z0-9_]',
      '\W' => '[^a-zA-Z0-9_]',
      '\s' => '[\r\n\t\f\v ]',
      '\S' => '[^\r\n\t\f\v ]',
      '\d' => '[0-9]',
      '\D' => '[^0-9]',
      '(?:' => '('
    }.each do |k, v|
      text = text.gsub k, v
    end
    text
  end
end
