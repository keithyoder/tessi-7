# frozen_string_literal: true

# == Schema Information
#
# Table name: atendimento_detalhes
#
#  id             :bigint           not null, primary key
#  descricao      :text
#  tipo           :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  atendente_id   :bigint
#  atendimento_id :bigint
#
# Indexes
#
#  index_atendimento_detalhes_on_atendente_id    (atendente_id)
#  index_atendimento_detalhes_on_atendimento_id  (atendimento_id)
#
# Foreign Keys
#
#  fk_rails_...  (atendente_id => users.id)
#  fk_rails_...  (atendimento_id => atendimentos.id)
#
class AtendimentoDetalhe < ApplicationRecord
  belongs_to :atendimento
  belongs_to :atendente, class_name: 'User'

  enum :tipo, {
    Presencial: 1,
    Telefone: 2,
    WhatsApp: 3,
    Facebook: 4,
    Email: 5
  }

  validate :nao_contem_dados_de_cartao?

  private

  def nao_contem_dados_de_cartao?
    return unless descricao.gsub(/[^a-zA-Z0-9]/, '').match?(/\d{13,16}/)

    errors.add(:descricao, 'não pode ter dados de cartão')
  end
end
