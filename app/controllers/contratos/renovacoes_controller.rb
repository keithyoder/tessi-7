# frozen_string_literal: true

module Contratos
  class RenovacoesController < BaseController
    RESPONSAVEL_PADRAO_ID = 5
    PERFIS_COM_ATENDIMENTO = %w[Boleto API].freeze

    # POST /contratos/:contrato_id/renovacao
    def create
      authorize! :renovar, @contrato

      faturas_geradas = Contratos::RenovarService.new(
        contrato: @contrato,
        meses_por_fatura: renovacao_params[:meses_por_fatura]
      ).call

      if faturas_geradas.present?
        abrir_atendimento_se_boleto

        count = faturas_geradas.count
        notice = "#{count} #{'fatura'.pluralize(count)} gerada#{'s' if count > 1} com sucesso."
      else
        notice = 'Não há meses restantes para renovar o contrato.'
      end

      redirect_to @contrato, notice: notice
    rescue StandardError => e
      redirect_to @contrato, alert: "Erro ao renovar contrato: #{e.message}"
    end

    private

    # Só abre atendimento de envio de boleto quando o contrato é cobrado
    # por boleto (registrado via banco ou via API). Débito Automático não
    # precisa desse acompanhamento.
    def abrir_atendimento_se_boleto
      return unless PERFIS_COM_ATENDIMENTO.include?(@contrato.pagamento_perfil.tipo)

      Contratos::AbrirAtendimentoRenovacaoService.call(
        contrato: @contrato,
        responsavel: responsavel_renovacao,
        aberto_por: current_user
      )
    end

    # Se for um admin renovando, o responsável pela entrega do boleto
    # é fixo (id 5). Qualquer outra pessoa é responsável pela própria renovação.
    def responsavel_renovacao
      current_user.admin? ? User.find(RESPONSAVEL_PADRAO_ID) : current_user
    end

    def renovacao_params
      params.permit(:meses_por_fatura)
    end
  end
end
