# frozen_string_literal: true

module Filterator
  class V1
    # I'm fairly sure most of this class works by magic, rather than by any design.

    # This thing turns strings of characters into strings of binary digits, where the binary digits come from the
    # character ordinals of each character in the string.
    # For each character, convert its ordinal to binary, pad the result with 0's so it's 8 digits long, and append the
    # 8 digits generated to an array; that array gets joined into one long string, which is what actually gets stored in
    # this hash.
    @generator = Hash.new do |h, k|
      chars = k.chars
      mappings = AppConfig['api_field_mappings']
      h[k] = chars.map.with_index do |c, i|
        if i < chars.size - 1
          c.ord.to_s(2).rjust(8, '0')
        else
          rem = mappings.size % 8
          rem = 8 if rem == 0
          c.ord.to_s(2).rjust(rem, '0')
        end
      end.join('')
    end

    # This takes a Base64-encoded filter string and turns it into an array of database-level qualified database column
    # names.
    # Uses @generator to turn the decoded Base64 into a binary string; turns the string into an array of 0's and 1's,
    # and zips the result together with the API field mappings in config. Selects only the fields that now have a 1 next
    # to them, and returns the resulting list of field names.
    def self.fields_from_string(encoded)
      raw = Base64.decode64(encoded)
      bitstring = @generator[raw]
      bits = bitstring.chars.map(&:to_i)
      AppConfig['api_field_mappings'].zip(bits).map { |k, v| k if v == 1 }.compact
    end

    # This is precisely the opposite of the previous method: given a list of database-level qualified column names, turns
    # them into a Base64-encoded filter string.
    # Creates an array the length of the API field mappings in config, and populates it - for each index, if the field at
    # that index in the mappings is present in the list of fields passed to this method, the array will be populated with
    # a 1; 0 if not. Chops the array into groups of 8, parses each group of 8 as a binary number to turn it to decimal,
    # and then turns the decimals into their respective characters. Finally, Base64 encodes the lot and returns it.
    def self.string_from_fields(fields)
      mappings = AppConfig['api_field_mappings']
      bits = Array.new(mappings.size) do |i|
        fields.include?(mappings[i]) ? 1 : 0
      end
      raw = bits.each_slice(8).map { |x| x.join('').to_i(2).chr }.join('')
      Base64.encode64(raw)
    end
  end

  class V2
    # This class is slightly less magic than V1.
    # Filters look like this: HJHGJJKKIIKKNMGOJILKKMMJFLOOKIGNONNMGK
    # TL;DR: It's a binary bitfield, turned into a decimal integer, and each digit is turned into a character.

    def self.filter_from_fields(fields)
      mappings = AppConfig['api_field_mappings']
      bits = Array.new(mappings.size) do |i|
        fields.include?(mappings[i]) ? 1 : 0
      end
      as_int = bits.join.to_i(2)
      as_int.to_s.chars.map { |c| (c.to_i + 70).chr }.join
    end

    def self.fields_from_filter(filter)
      as_int = filter.chars.map { |c| c.ord - 70 }.join.to_i
      bits = as_int.to_s(2).rjust(AppConfig['api_field_mappings'].size, '0').chars.map(&:to_i)
      AppConfig['api_field_mappings'].zip(bits).map { |k, v| k if v == 1 }.compact - AppConfig['sensitive_fields']
    end
  end
end
