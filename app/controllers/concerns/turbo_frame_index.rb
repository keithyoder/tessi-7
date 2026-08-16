# frozen_string_literal: true

# Dá a uma index a capacidade de ser exibida tanto como página avulsa
# quanto embutida como aba de outro recurso (Servidor, Pessoa, Contrato,
# etc.), usando um turbo-frame cujo id muda de acordo com o escopo.
#
# Uso:
#
#   class PontosController < ApplicationController
#     include TurboFrameIndex
#     escopavel_por :servidor_id
#
#     def index
#       @q = aplicar_escopo(Ponto.all).ransack(params[:q])
#       ...
#     end
#   end
module TurboFrameIndex
  extend ActiveSupport::Concern

  included do
    layout -> { turbo_frame_request? ? false : 'application' }
    helper_method :id_frame, :incorporado?
    class_attribute :parametros_escopo, default: [].freeze
  end

  class_methods do
    # Declara por quais parâmetros esta index pode ser filtrada quando
    # incorporada como aba de outro recurso, por exemplo:
    #   escopavel_por :pessoa_id, :contrato_id, :conexao_id
    def escopavel_por(*parametros)
      self.parametros_escopo = parametros.freeze
    end
  end

  private

  # Verdadeiro quando a index está sendo exibida como aba incorporada,
  # em vez da página avulsa.
  def incorporado?
    parametros_escopo.any? { |parametro| params[parametro].present? }
  end

  # Id do turbo-frame da index. Na página avulsa usa um id fixo; quando
  # incorporada, gera um id compatível com o que a aba do outro recurso
  # espera, por exemplo "servidor_12_pontos".
  def id_frame
    escopo = parametros_escopo.find { |parametro| params[parametro].present? }
    return "#{controller_name}_index" unless escopo

    "#{escopo.to_s.delete_suffix('_id')}_#{params[escopo]}_#{controller_name}"
  end

  # Aplica os where clauses de escopo (quando presentes) a uma consulta
  # já montada pelo controller. Cada controller ainda monta sua própria
  # query base (joins, select, includes) — isso só resolve o filtro.
  def aplicar_escopo(consulta)
    parametros_escopo.each do |parametro|
      consulta = consulta.where(parametro => params[parametro]) if params[parametro].present?
    end
    consulta
  end
end
