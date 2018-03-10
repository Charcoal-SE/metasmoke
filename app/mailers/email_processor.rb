class EmailProcessor
  def initialize(email)
    @email = email
  end

  def process
    Rails.logger.info(email)
  end
end
