# frozen_string_literal: true

module Faturamento
  # Queries compartilhadas para buscar dados de faturas
  module Queries
    module_function

    # Carrega faturamento agrupado por dia em um perÃ­odo
    #
    # @param data_inicio [Date]
    # @param data_fim [Date]
    # @return [Hash] dia => { quantidade, total }
    def faturamento_por_dia(data_inicio, data_fim)
      resultado = Fatura
        .where(liquidacao: data_inicio..data_fim)
        .group(Arel.sql('EXTRACT(day FROM liquidacao)'))
        .reorder(nil)
        .select(
          Arel.sql('EXTRACT(day FROM liquidacao)::int as dia'),
          Arel.sql('COUNT(*) as quantidade'),
          Arel.sql('COALESCE(SUM(valor_liquidacao), 0) as total')
        )

      resultado.index_by(&:dia)
    end

    # Carrega faturamento agrupado por mÃªs em um perÃ­odo
    #
    # @param data_inicio [Date]
    # @param data_fim [Date]
    # @return [Hash] mes => { quantidade, total }
    def faturamento_por_mes(data_inicio, data_fim)
      resultado = Fatura
        .where(liquidacao: data_inicio..data_fim)
        .group(Arel.sql('EXTRACT(month FROM liquidacao)'))
        .reorder(nil)
        .select(
          Arel.sql('EXTRACT(month FROM liquidacao)::int as mes'),
          Arel.sql('COUNT(*) as quantidade'),
          Arel.sql('COALESCE(SUM(valor_liquidacao), 0) as total')
        )

      resultado.index_by(&:mes)
    end

    # Carrega faturamento total em um perÃ­odo
    #
    # @param data_inicio [Date]
    # @param data_fim [Date]
    # @return [Hash] com :quantidade e :total
    def faturamento_total(data_inicio, data_fim)
      resultado = Fatura
        .where(liquidacao: data_inicio..data_fim)
        .reorder(nil)
        .select(
          Arel.sql('COUNT(*) as quantidade'),
          Arel.sql('COALESCE(SUM(valor_liquidacao), 0) as total')
        )
        .take

      {
        quantidade: resultado&.quantidade || 0,
        total: resultado&.total.to_f
      }
    end

    # Carrega breakdown por meio de liquidaÃ§Ã£o
    #
    # @param data_inicio [Date]
    # @param data_fim [Date]
    # @return [Hash] meio => total
    def faturamento_por_meio(data_inicio, data_fim)
      Fatura
        .where(liquidacao: data_inicio..data_fim)
        .group(:meio_liquidacao)
        .reorder(nil)
        .sum(:valor_liquidacao)
    end

    # Carrega dados histÃ³ricos agrupados por ano e mÃªs
    #
    # @param anos [Array<Integer>] lista de anos
    # @return [Hash] ano => { mes => total }
    def faturamento_historico_por_ano_mes(anos)
      return {} if anos.empty?

      data_inicio = Date.new(anos.min, 1, 1)
      data_fim = Date.new(anos.max, 12, 31)

      resultado = Fatura
        .where(liquidacao: data_inicio..data_fim)
        .group(
          Arel.sql('EXTRACT(year FROM liquidacao)'),
          Arel.sql('EXTRACT(month FROM liquidacao)')
        )
        .reorder(nil)
        .select(
          Arel.sql('EXTRACT(year FROM liquidacao)::int as ano'),
          Arel.sql('EXTRACT(month FROM liquidacao)::int as mes'),
          Arel.sql('COALESCE(SUM(valor_liquidacao), 0) as total')
        )

      # Converte para hash aninhado: { ano => { mes => total } }
      dados = {}
      resultado.each do |r|
        dados[r.ano] ||= {}
        dados[r.ano][r.mes] = r.total.to_f
      end
      dados
    end

    # Carrega breakdown por tipo de pessoa
    #
    # @param data_inicio [Date]
    # @param data_fim [Date]
    # @return [Hash] tipo => quantidade
    def faturamento_por_tipo_pessoa(data_inicio, data_fim)
      Fatura
        .where(liquidacao: data_inicio..data_fim)
        .joins(contrato: :pessoa)
        .group('pessoas.tipo')
        .reorder(nil)
        .count
    end

    # Carrega breakdown por perfil de pagamento
    #
    # @param data_inicio [Date]
    # @param data_fim [Date]
    # @return [Hash] perfil => total
    def faturamento_por_perfil(data_inicio, data_fim)
      Fatura
        .where(liquidacao: data_inicio..data_fim)
        .joins(:pagamento_perfil)
        .group('pagamento_perfis.nome')
        .reorder(nil)
        .sum(:valor_liquidacao)
    end
  end
end
