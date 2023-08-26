# frozen_string_literal: true

module Fixy
  module Formatter
    module Numeric
      def format_numeric(input, length)
        input = if input.blank?
                  0.to_s
                else
                  input.to_s
                end
        raise ArgumentError, 'Invalid Input (only digits are accepted)' unless input =~ /^\d+$/
        raise ArgumentError, "Not enough length (input: #{input}, length: #{length})" if input.length > length

        input.rjust(length, '0')
      end
    end
  end
end
