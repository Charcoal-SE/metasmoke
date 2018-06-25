# frozen_string_literal: true

# - - - - - - - - - - - - - - - - -  WARNING  - - - - - - - - - - - - - - - - -
# This entire file is a hack. Use anything defined or written here at your own
# risk. While Rails' internal routes structure is complicated, it's like that
# for a reason - because it's useful internally and it's not meant to be used
# by consumer code.
#
# So I went ahead and used it. Of course.
#
# This code:
#  (a) works tenuously at best
#  (b) doesn't follow best practices
#  (c) will almost certainly break horribly at the first sign of a change in
#      Rails itself
#  (d) is highly experimental and should probably never be used, etc, etc.
#
# Consider yourself warned.

class SensibleRoute
  attr_reader :path, :url_details, :parameters, :verb

  def initialize(rt)
    @parameters = []

    formatter = rt.path.build_formatter
    parts = []

    internal = formatter.instance_variable_get :@parts
    internal.each do |part|
      if part.is_a? String
        parts << part
      elsif part.is_a? ActionDispatch::Journey::Format::Parameter
        parts << ":#{part.name}"
        @parameters << part.name
      end
    end

    @path = parts.join
    @url_details = rt.requirements
    @verb = rt.verb
  end
end
