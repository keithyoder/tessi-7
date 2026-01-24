# frozen_string_literal: true

module ConexoesHelper
  def conexoes_params(params)
    params.permit(
      :tab, :sem_autenticar, :suspensas, :ativas, :conectadas, :desconectadas,
      :sem_contrato, conexao_q: [:usuario_or_mac_or_pessoa_nome_cont]
    )
  end

  def parcelas_instalacao_display
    return '' unless @contrato.valor_instalacao.positive?
    return 'À Vista' if @contrato.parcelas_instalacao.zero?

    @contrato.parcelas_instalacao
  end

  def parcelas_vencimento
    return '' unless @contrato.parcelas_instalacao.positive?

    @contrato.faturas.first(@contrato.parcelas_instalacao).map { |f| I18n.l(f.vencimento) }.join(', ')
  end
end
