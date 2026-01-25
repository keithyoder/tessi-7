# frozen_string_literal: true

module Spec
  module ModelHelpers
    #
    # === Generic helpers ===
    #

    def any_date
      Date.current
    end

    def any_date_in_the_past
      1.month.ago.to_date
    end

    def any_date_in_the_future
      1.month.from_now.to_date
    end

    #
    # === Core domain helpers ===
    #

    def any_pessoa_fisica(_attrs = {})
      @any_pessoa_fisica ||= create(:pessoa, :fisica)
    end

    def any_plano(attrs = {})
      @any_plano ||= create(
        :plano,
        { nome: 'Plano Default', mensalidade: 100.0 }.merge(attrs)
      )
    end

    def any_contrato(attrs = {})
      adesao_date = attrs.delete(:adesao) || Date.new(2026, 1, 10)

      create(
        :contrato,
        {
          pessoa: any_pessoa_fisica,
          plano: any_plano,
          adesao: adesao_date,
          dia_vencimento: adesao_date.day,
          pagamento_perfil: any_pagamento_perfil,
          parcelas_instalacao: 0,
          primeiro_vencimento: adesao_date + 1.month
        }.merge(attrs)
      )
    end

    def any_pagamento_perfil(_attrs = {})
      @any_pagamento_perfil ||= create(
        :pagamento_perfil
      )
    end

    def any_fatura(attrs = {})
      create(
        :fatura,
        {
          contrato: any_contrato,
          periodo_inicio: Date.new(2026, 1, 10),
          periodo_fim: Date.new(2026, 2, 9),
          valor: 100.0
        }.merge(attrs)
      )
    end

    #
    # === Billing helpers ===
    #

    def contrato_com_faturas(quantidade:, meses_por_fatura: 1)
      contrato = any_contrato

      Faturas::GerarService.call(
        contrato: contrato,
        quantidade: quantidade,
        meses_por_fatura: meses_por_fatura
      )

      contrato
    end

    def admin_user(attrs = {})
      create(
        :user,
        {
          role: :admin,
          confirmed_at: Time.current
        }.merge(attrs)
      )
    end
  end
end
