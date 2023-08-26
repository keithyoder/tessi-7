# frozen_string_literal: true

class TrueClass
  def as_checkbox
    '❌'
  end

  def as_simnao
    'sim'
  end
end

class FalseClass
  def as_checkbox
    '⭕️'
  end

  def as_simnao
    'não'
  end
end

class NilClass
  def as_checkbox
    ''
  end

  def as_simnao
    ''
  end

  def as_string
    ''
  end
end
