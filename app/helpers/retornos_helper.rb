# frozen_string_literal: true

module RetornosHelper
  def cnab_to_float(str)
    str.to_f / 100
  end

  def cnab_to_currency(str)
    number_to_currency(str.to_f / 100)
  end

  def cnab_to_date(str)
    Date.strptime(str, '%d%m%y')
  end

  def cnab_to_nosso_numero_santander(str)
    # remove leading zeros and trailing digit
    str.sub!(/^0+/, '')[0...-1]
  end

  def cnab_to_nosso_numero_bb(str)
    str[10..].sub!(/^0+/, '')
  end
end
