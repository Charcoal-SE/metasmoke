class Redis::StackExchangeUser
  attr_reader :fields, :id

  def initialize(id, **overrides)
    @id = id
    @fields = overrides
  end

  %w[username].each do |m|
    define_method(m) { @fields[m] }
  end
end
