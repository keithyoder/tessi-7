# frozen_string_literal: true

module Contratos
  class CleanupAutentiqueJob < ApplicationJob
    queue_as :default

    def perform
      client = Autentique.client
      limit = 60
      page = 1

      loop do
        response = with_retry { client.documents.pending(limit: limit, page: page) }
        docs = response[:documents]
        total = response[:total]

        Rails.logger.info "CleanupAutentiqueJob: processando página #{page} — #{docs.size} documentos"

        processar_pagina(client, docs)

        break if page * limit >= total

        sleep 0.5
        page += 1
      end

      Rails.logger.info 'CleanupAutentiqueJob: concluído'
    end

    private

    def processar_pagina(client, docs)
      docs.each do |doc|
        motivo = motivo_orfao(doc)
        next unless motivo

        Rails.logger.info "CleanupAutentiqueJob: processando #{doc.id} (#{doc.name}) — #{motivo}"

        with_retry { client.documents.reject(doc.id, reason: motivo) }
        with_retry { client.documents.delete(doc.id) }

        Rails.logger.info "CleanupAutentiqueJob: documento #{doc.id} rejeitado e excluído"
      rescue Autentique::Error => e
        Rails.logger.error "CleanupAutentiqueJob: falha ao processar #{doc.id} — #{e.message}"
      end
    end

    def motivo_orfao(doc)
      id = doc.name.scan(/\d+/).first&.to_i
      return 'Nenhum ID de contrato encontrado no nome do documento' if id.nil?

      contrato = Contrato.find_by(id: id)
      return 'Contrato não encontrado' if contrato.nil?

      'Contrato já possui documento assinado' if Array(contrato.documentos).any?
    end

    def with_retry(attempts: 3, wait: 2)
      attempt = 1
      begin
        yield
      rescue Autentique::Error, OpenSSL::SSL::SSLError => e
        if attempt < attempts
          Rails.logger.warn "CleanupAutentiqueJob: tentativa #{attempt} falhou, tentando novamente — #{e.message}"
          sleep wait * attempt
          attempt += 1
          retry
        end
        raise
      end
    end
  end
end
