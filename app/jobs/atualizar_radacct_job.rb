# frozen_string_literal: true

class AtualizarRadacctJob < ApplicationJob
  queue_as :default

  def perform
    query = <<-SQL
        update radacct set pessoa_id = conexoes.pessoa_id
        from conexoes where acctstoptime > $1
        and radacct.username = conexoes.usuario
        and radacct.framedipaddress = conexoes.ip
        and radacct.pessoa_id is null
    SQL

    ActiveRecord::Base.connection.exec_update(query, 'SQL', [[nil, 1.week.ago]])
  end
end

# Sidekiq::Cron::Job.create(name: 'Gravar usuario com radacct', cron: '20 3 * * *', class: 'AtualizarRadacctJob')
