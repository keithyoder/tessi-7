# frozen_string_literal: true

# app/domain/faturamento/periods.rb

module Faturamento
  # Manipulação e validação de períodos de data
  module Periods
    module_function

    # Retorna o range de datas para um ano, limitado até hoje
    #
    # @param ano [Integer]
    # @return [Range<Date>] range de datas
    def ano_range(ano)
      inicio = Date.new(ano, 1, 1)
      fim = Date.new(ano, 12, 31)
      fim = [fim, Date.current].min

      inicio..fim
    end

    # Retorna o range de datas para um mês, limitado até hoje
    #
    # @param ano [Integer]
    # @param mes [Integer]
    # @return [Range<Date>] range de datas
    def mes_range(ano, mes)
      inicio = Date.new(ano, mes, 1)
      fim = inicio.end_of_month
      fim = [fim, Date.current].min

      inicio..fim
    end

    # Retorna o último dia disponível de um mês (hoje se for mês atual)
    #
    # @param ano [Integer]
    # @param mes [Integer]
    # @return [Date]
    def ultimo_dia_disponivel(ano, mes)
      fim_mes = Date.new(ano, mes, 1).end_of_month
      [fim_mes, Date.current].min
    end

    # Verifica se um ano/mês é o mês atual
    #
    # @param ano [Integer]
    # @param mes [Integer]
    # @return [Boolean]
    def mes_atual?(ano, mes)
      Date.current.year == ano && Date.current.month == mes
    end

    # Valida se um ano está dentro do range permitido
    #
    # @param ano [Integer]
    # @param ano_minimo [Integer] default: 2020
    # @return [Boolean]
    def ano_valido?(ano, ano_minimo: 2020)
      ano.between?(ano_minimo, Date.current.year + 1)
    end

    # Valida se um mês está dentro do range permitido
    #
    # @param mes [Integer]
    # @return [Boolean]
    def mes_valido?(mes)
      mes.between?(1, 12)
    end

    # Valida se uma data não é futura
    #
    # @param data [Date]
    # @return [Boolean]
    def data_valida?(data)
      data <= Date.current
    end

    # Calcula número de meses completos entre duas datas
    #
    # @param data_inicio [Date]
    # @param data_fim [Date]
    # @return [Integer] número de meses
    def meses_entre(data_inicio, data_fim)
      meses = 0
      current = data_inicio.beginning_of_month

      while current <= data_fim.beginning_of_month
        meses += 1
        current += 1.month
      end

      meses
    end

    # Retorna range de datas para período parcial (mesmo dia do mês em anos anteriores)
    #
    # @param ano [Integer] ano histórico
    # @param mes [Integer]
    # @param dia_limite [Integer] dia atual do mês
    # @return [Range<Date>]
    def periodo_parcial_historico(ano, mes, dia_limite)
      inicio = Date.new(ano, mes, 1)
      fim = inicio.end_of_month
      dia = [dia_limite, fim.day].min
      fim = Date.new(ano, mes, dia)

      inicio..fim
    end
  end
end
