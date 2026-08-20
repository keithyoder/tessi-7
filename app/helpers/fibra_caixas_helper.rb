# frozen_string_literal: true

module FibraCaixasHelper
  def ativas_badge_class(ativas, total)
    return 'bg-danger' if ativas.zero?

    pct = (ativas.to_f / total * 100).round
    if pct <= 50
      'bg-warning'
    elsif pct <= 75
      'bg-info'
    else
      'bg-success'
    end
  end
end
