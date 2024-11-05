# frozen_string_literal: true

# == Schema Information
#
# Table name: plano_verificar_atributos
#
#  id         :bigint           not null, primary key
#  atributo   :string
#  op         :string
#  valor      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  plano_id   :bigint
#
# Indexes
#
#  index_plano_verificar_atributos_on_plano_id               (plano_id)
#  index_plano_verificar_atributos_on_plano_id_and_atributo  (plano_id,atributo) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (plano_id => planos.id) ON DELETE => cascade
#
class PlanoVerificarAtributo < ApplicationRecord
  belongs_to :plano
end
