module SpamWavesHelper
  def help_or_error(field, help = nil, &block)
    if @errors.any? && @errors.messages.include?(field)
      field.to_s.humanize + ' ' + @errors.messages[field].first
    else
      if block_given?
        capture(&block)
      else
        help
      end
    end
  end

  def error?(field)
    @errors.any? && @errors.messages.include?(field)
  end

  def default(field, wave = nil, default = nil)
    if field.to_s.include? '['
      (wave.conditions[field.to_s.split('[')[1].tr(']', '')] rescue nil) || params[field] || default
    else
      (wave&.send(field) rescue nil) || params[field] || default
    end
  end
end
