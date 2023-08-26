# frozen_string_literal: true

module Fixy
  module Formatter
    module Date
      def format_date(input, length)
        if input.blank?
          input = '00000000'
        else
          input = input.strftime('%Y%m%d')
          raise ArgumentError, 'Invalid Input (only digits are accepted)' unless input =~ /^\d+$/
          raise ArgumentError, "Not enough length (input: #{input}, length: #{length})" if input.length > length

          input.rjust(length, '0')
        end
      end
    end
  end
end
