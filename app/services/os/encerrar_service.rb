# frozen_string_literal: true

class Os::EncerrarService # rubocop:disable Style/ClassAndModuleChildren
  def initialize(os:, resultado:, encerramento: nil, tecnico_1_id: nil, tecnico_2_id: nil, fechamento: nil) # rubocop:disable Metrics/ParameterLists
    @os = os
    @resultado = resultado
    @encerramento = encerramento
    @tecnico_1_id = tecnico_1_id
    @tecnico_2_id = tecnico_2_id
    @fechamento = fechamento
  end

  def call
    ApplicationRecord.transaction do
      fechamento_final = fechamento.presence || DateTime.now

      os.update!(
        resultado: resultado,
        encerramento: encerramento,
        tecnico_1_id: tecnico_1_id,
        tecnico_2_id: tecnico_2_id,
        fechamento: fechamento_final,
        agendado_em: fechamento_final
      )
      criar_os_reagendada if os.requer_reagendamento?
    end
    os
  end

  private

  attr_reader :os, :resultado, :encerramento, :tecnico_1_id, :tecnico_2_id, :fechamento

  def criar_os_reagendada
    Os.create!(
      pessoa: os.pessoa,
      conexao: os.conexao,
      classificacao: os.classificacao,
      tipo: os.tipo,
      aberto_por: os.responsavel,
      responsavel: os.responsavel,
      descricao: "Reagendamento da OS ##{os.id}\n\n#{os.descricao}",
      os_origem_id: os.id
    )
  end
end
