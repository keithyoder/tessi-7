# frozen_string_literal: true

# == Schema Information
#
# Table name: radpostauth
#
#  id               :bigint           not null, primary key
#  authdate         :timestamptz      not null
#  calledstationid  :text
#  callingstationid :text
#  pass             :text
#  reply            :text
#  username         :text             not null
#
# Indexes
#
#  radpostauth_username_authdate_idx  (username,authdate)
#
class Autenticacao < ApplicationRecord
  self.table_name = 'radpostauth'
  self.primary_key = 'id'
  belongs_to :conexao, primary_key: :username, foreign_key: :usuario
end
