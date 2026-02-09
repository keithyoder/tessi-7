# frozen_string_literal: true

FactoryBot.define do
  factory :conexao do
    pessoa { association :pessoa, :fisica }
    plano
    ponto
    sequence(:ip) { |n| "192.168.1.#{n}" }
    sequence(:usuario) { |n| "user#{n}" }
    sequence(:mac) { |n| format('%02x:%02x:%02x:%02x:%02x:%02x', (n >> 40) & 0xff, (n >> 32) & 0xff, (n >> 24) & 0xff, (n >> 16) & 0xff, (n >> 8) & 0xff, n & 0xff) } # rubocop:disable Style/FormatStringToken
    senha { 'password123' }
    auto_bloqueio { true }
    bloqueado { false }
    inadimplente { false }
  end
end
