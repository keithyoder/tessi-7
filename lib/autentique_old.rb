# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'

module AutentiqueOld
  HTTP = GraphQL::Client::HTTP.new('https://api.autentique.com.br/v2/graphql') do
    def headers(_context)
      { Authorization: "Bearer #{Rails.application.credentials.autentique_key}" }
    end
  end

  # Lazily initialize client
  def self.client
    @client ||= begin
      schema = GraphQL::Client.load_schema(HTTP)
      GraphQL::Client.new(schema: schema, execute: HTTP)
    end
  end

  # Lazily define queries/mutations
  def self.resgatar_documento # rubocop:disable Metrics/MethodLength
    @resgatar_documento ||= client.parse <<-GRAPHQL
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
  end

  def self.criar_documento # rubocop:disable Metrics/MethodLength
    @criar_documento ||= client.parse <<-GRAPHQL
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
  end

  def self.documentos_com_pendencia # rubocop:disable Metrics/MethodLength
    @documentos_com_pendencia ||= client.parse <<-GRAPHQL
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
  end
end
