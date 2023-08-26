# frozen_string_literal: true

module ConexoesHelper
  def conexoes_params(params)
    params.permit(
      :tab, :sem_autenticar, :suspensas, :ativas, :conectadas, :desconectadas,
      :sem_contrato
    )
  end

  def parcelas_instalacao_display
    return '' unless @contrato.valor_instalacao > 0
    return 'À Vista' if @contrato.parcelas_instalacao == 0

    @contrato.parcelas_instalacao
  end

  def parcelas_vencimento
    return '' unless @contrato.parcelas_instalacao > 0

    @contrato.faturas.first(@contrato.parcelas_instalacao).map { |f| I18n.localize(f.vencimento)}.join(', ')
  end
end
