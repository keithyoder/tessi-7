# frozen_string_literal: true

module RetornosHelper
  def cnab_to_float(s)
    s.to_f / 100
  end

  def cnab_to_currency(s)
    number_to_currency(s.to_f / 100)
  end

  def cnab_to_date(s)
    Date.strptime(s, '%d%m%y')
  end

  def cnab_to_nosso_numero_santander(s)
    # remove leading zeros and trailing digit
    s.sub!(/^0+/, '')[0...-1]
  end

  def cnab_to_nosso_numero_bb(s)
    s[10..-1].sub!(/^0+/, '')
  end
end
