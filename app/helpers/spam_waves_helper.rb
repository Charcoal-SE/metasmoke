# frozen_string_literal: true

module SpamWavesHelper
  def help_or_error(field, help = nil, &block)
    if @errors.any? && @errors.messages.include?(field)
      field.to_s.humanize + ' ' + @errors.messages[field].first
    elsif block_given?
      capture(&block)
    else
      help
    end
  end

  def error?(field)
    @errors.any? && @errors.messages.include?(field)
  end

  def default(field, wave = nil, default = nil)
    if field.to_s.include? '['
      (begin
         wave.conditions[field.to_s.split('[')[1].tr(']', '')]
       rescue
         nil
       end) || params[field] || default
    else
      (begin
         wave&.send(field)
       rescue
         nil
       end) || params[field] || default
    end
  end
end
