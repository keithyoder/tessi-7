# frozen_string_literal: true

FactoryBot.define do
  factory :ubiquiti_device, class: 'Devices::Ubiquiti' do
    deviceable factory: %i[ponto]
  end
end
