# frozen_string_literal: true

module NumberHelper
  def number_to_multiplicative_quantifier(n)
    return 'once' if n == 1
    return 'twice' if n == 2

    "#{n} times"
  end
end
