# frozen_string_literal: true

class RadAcct < ApplicationRecord
  self.table_name = 'radacct'
  self.primary_key = 'radacctid'
  belongs_to :conexao, primary_key: :username, foreign_key: :usuario
  scope :trafego, lambda {
    select('date(acctstoptime) as dia, sum(acctoutputoctets) as download, sum(acctinputoctets) as upload')
      .where('not acctstoptime is null and acctstoptime > ?', 180.days.ago)
      .group('date(acctstoptime)')
      .order('date(acctstoptime) desc')
      .limit(90)
  }

  def self.codef(mes)
    RadAcct.where("date_trunc('month', acctstarttime) = ?", mes)
           .sum('(acctinputoctets + acctoutputoctets) / (1024 * 1024)').to_i
  end
end
