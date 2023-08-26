# frozen_string_literal: true

class Autenticacao < ApplicationRecord
  self.table_name = 'radpostauth'
  self.primary_key = 'id'
  belongs_to :conexao, primary_key: :username, foreign_key: :usuario
end
