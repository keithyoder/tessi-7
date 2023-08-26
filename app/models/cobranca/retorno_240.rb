# frozen_string_literal: true

require 'parseline'

class Retorno240Header
  attr_accessor :sequencia, :data, :convenio, :banco

  extend ParseLine::FixedWidth

  fixed_width_layout do |parse|
    parse.field :banco, 0..2
    parse.field :convenio, 52..62
    parse.field :data, 143..152
    parse.field :sequencia, 157..162
  end
end
