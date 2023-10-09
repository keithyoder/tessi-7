# frozen_string_literal: true

module Fixy
  module Formatter
    module Amount
      def format_amount(input, length)
        input = (input * 100).to_i.to_s
        raise ArgumentError, 'Invalid Input (only digits are accepted)' unless input =~ /^\d+$/
        raise ArgumentError, "Not enough length (input: #{input}, length: #{length})" if input.length > length

        input.rjust(length, '0')
      end
    end
  end
end
