# frozen_string_literal: true

# == Schema Information
#
# Table name: radacct
#
#  acctauthentic       :text
#  acctinputoctets     :bigint
#  acctinterval        :bigint
#  acctoutputoctets    :bigint
#  acctsessionid       :text             not null
#  acctsessiontime     :bigint
#  acctstarttime       :timestamptz
#  acctstoptime        :timestamptz
#  acctterminatecause  :text
#  acctuniqueid        :text             not null
#  acctupdatetime      :timestamptz
#  calledstationid     :text
#  callingstationid    :text
#  connectinfo_start   :text
#  connectinfo_stop    :text
#  delegatedipv6prefix :string
#  framedipaddress     :inet
#  framedipv6address   :string
#  framedprotocol      :text
#  groupname           :text
#  nasipaddress        :inet             not null
#  nasportid           :text
#  nasporttype         :text
#  radacctid           :bigint           not null, primary key
#  realm               :text
#  servicetype         :text
#  username            :text
#  pessoa_id           :bigint
#
# Indexes
#
#  index_radacct_on_username_and_acctstarttime  (username,acctstarttime)
#  radacct_acctuniqueid_key                     (acctuniqueid) UNIQUE
#  radacct_active_session_idx                   (acctuniqueid) WHERE (acctstoptime IS NULL)
#  radacct_bulk_close                           (nasipaddress,acctstarttime) WHERE (acctstoptime IS NULL)
#  radacct_start_user_idx                       (acctstarttime,username)
#
# Foreign Keys
#
#  fk_pessoa_id  (pessoa_id => pessoas.id)
#
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
