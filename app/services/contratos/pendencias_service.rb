# frozen_string_literal: true

module Contratos
  class PendenciasService
    class Error < StandardError; end

    def initialize(client: Autentique.client)
      @client = client
    end

    # Returns an array of hashes with :documento and :contrato keys
    def call(limit: 60, page: 1)
      documents = @client.documents.pending(limit: limit, page: page)
      return [] unless documents.is_a?(Array) && documents.any?

      ids = documents.filter_map { |doc| doc.name.scan(/\d+/).first&.to_i }
      contratos = Contrato.where(id: ids).includes(:pessoa).index_by(&:id)

      documents.map do |doc|
        id = doc.name.scan(/\d+/).first&.to_i
        { documento: doc, contrato: contratos[id] }
      end
    rescue Autentique::AuthenticationError,
           Autentique::RateLimitError,
           Autentique::ValidationError,
           Autentique::QueryError,
           Autentique::UploadError,
           StandardError => e
      raise Error, "Falha ao buscar documentos pendentes: #{e.message}"
    end
  end
end