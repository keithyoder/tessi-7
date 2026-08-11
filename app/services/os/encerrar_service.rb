# frozen_string_literal: true

class Os::EncerrarService # rubocop:disable Style/ClassAndModuleChildren
  def initialize(os:, resultado:, encerramento: nil, tecnico_1_id: nil, tecnico_2_id: nil)
    @os = os
    @resultado = resultado
    @encerramento = encerramento
    @tecnico_1_id = tecnico_1_id
    @tecnico_2_id = tecnico_2_id
  end

  def call
    ApplicationRecord.transaction do
      os.update!(
        resultado: resultado,
        encerramento: encerramento,
        tecnico_1_id: tecnico_1_id,
        tecnico_2_id: tecnico_2_id,
        fechamento: DateTime.now
      )
      criar_os_reagendada if os.requer_reagendamento?
    end
    os
  end

  private

  attr_reader :os, :resultado, :encerramento, :tecnico_1_id, :tecnico_2_id

  def criar_os_reagendada
    Os.create!(
      pessoa: os.pessoa,
      conexao: os.conexao,
      classificacao: os.classificacao,
      tipo: os.tipo,
      aberto_por: os.responsavel,
      responsavel: os.responsavel,
      descricao: "Reagendamento da OS ##{os.id}",
      os_origem_id: os.id
    )
  end
end
