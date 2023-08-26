# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

module Autentique
  HTTP = GraphQL::Client::HTTP.new('https://api.autentique.com.br/v2/graphql') do
    def headers(_context)
      { "Authorization": "Bearer #{Rails.application.credentials.autentique_key}" }
    end
  end
  Schema = GraphQL::Client.load_schema(HTTP)
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
  ResgatarDocumento = Autentique::Client.parse <<-'GRAPHQL'
    query($id: UUID!) {
      document(id: $id) {
        id
        name
        refusable
        sortable
        created_at
        files { original signed }
        signatures {
          public_id
          name
          email
          created_at
          action { name }
          link { short_link }
          user { id name email }
          email_events {
            sent
            opened
            delivered
            refused
            reason
          }
          viewed { ...event }
          signed { ...event }
          rejected { ...event }
        }
      }
    }

    fragment event on Event {
      ip
      port
      reason
      created_at
      geolocation {
        country
        countryISO
        state
        stateISO
        city
        zipcode
        latitude
        longitude
      }
    }
  GRAPHQL

  CriarDocumento = Autentique::Client.parse <<-'GRAPHQL'
    mutation(
      $document: DocumentInput!,
      $signers: [SignerInput!]!,
      $file: Upload!
    ) {
      createDocument(
        document: $document,
        signers: $signers,
        file: $file
      ) {
        id
        name
        refusable
        sortable
        created_at
        signatures {
          public_id
          name
          email
          created_at
          action { name }
          link { short_link }
          user { id name email }
        }
      }
    }
  GRAPHQL

  DocumentosComPendencia = Autentique::Client.parse <<-'GRAPHQL'
    query {
      documents(status: PENDING, limit: 60, page: 1) {
        total
        data {
          id
          name
          created_at
          signatures {
            public_id
            name
            email
            user { id name email phone }
            delivery_method
            email_events {
              sent
              opened
              delivered
              refused
              reason
            }
          }
        }
      }
    }
  GRAPHQL

  def self.processar_webhook(evento)
    Rails.logger.info 'Inciando processamento'
    return unless evento.webhook.tipo == 'autentique' && evento.processed_at.blank?

    documento = evento.body['documento']
    contrato = Contrato.find_by(id: documento['nome'].scan(/\d+/).first)
    return unless contrato

    documentos = [] if documentos.blank?
    contrato.update(documentos:
      documentos += [
        {
          'data': documento['created'],
          'nome': documento['nome'],
          'link': evento.body['arquivo']['assinado']
        }
      ])
    Rails.logger.info 'Webhook processado'
    evento.update(processed_at: DateTime.now)
  end
end
