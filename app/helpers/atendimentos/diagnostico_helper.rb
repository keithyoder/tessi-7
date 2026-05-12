# frozen_string_literal: true

module Atendimentos
  module DiagnosticoHelper
    def radio_conexao(conexao, checked)
      radio_button_tag(
        'conexao_selecionada',
        conexao[:id],
        checked,
        id: "conexao_#{conexao[:id]}",
        class: 'form-check-input',
        data: { action: 'change->diagnostico#selecionarConexao' }
      )
    end

    def label_conexao(conexao)
      label_tag(
        "conexao_#{conexao[:id]}",
        "#{conexao[:usuario]} — #{conexao[:endereco]}",
        class: 'form-check-label'
      )
    end
  end
end
