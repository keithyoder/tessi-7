# frozen_string_literal: true

# == Schema Information
#
# Table name: conexao_enviar_atributos
#
#  id         :bigint           not null, primary key
#  atributo   :string
#  op         :string
#  valor      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  conexao_id :bigint
#
# Indexes
#
#  index_conexao_enviar_atributos_on_conexao_id               (conexao_id)
#  index_conexao_enviar_atributos_on_conexao_id_and_atributo  (conexao_id,atributo) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (conexao_id => conexoes.id) ON DELETE => cascade
#
class ConexaoEnviarAtributo < ApplicationRecord
  belongs_to :conexao
end
