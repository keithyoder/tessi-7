# frozen_string_literal: true

Ransack.configure do |config|
  config.add_predicate 'no_accent', # Name your predicate
                       arel_predicate: 'matches',
                       formatter: proc { |s| transliterate(s) },
                       validator: proc(&:present?),
                       compounds: true,
                       type: :string
end

# needed because ransack 4.0 doesn't support Rails 7.1 yet.
module Arel
  class Table
    alias table_name name
  end
end
