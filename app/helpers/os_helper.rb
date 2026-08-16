# frozen_string_literal: true

module OsHelper
  def infraestrutura_tipo_humanizado(infraestrutura_type)
    case infraestrutura_type
    when 'Servidor' then 'Concentrador'
    when 'Ponto' then 'Ponto de Acesso'
    when 'FibraRede' then 'Rede de Fibra'
    when 'FibraCaixa' then 'Caixa de Atendimento'
    else infraestrutura_type
    end
  end
end
