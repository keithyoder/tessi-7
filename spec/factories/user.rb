# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password' }
    confirmed_at { Time.current }
    role { nil } # Default: no role

    trait :admin do
      role { 'admin' }
    end

    trait :financeiro_n1 do
      role { 'financeiro_n1' }
    end

    trait :financeiro_n2 do
      role { 'financeiro_n2' }
    end

    trait :tecnico_n1 do
      role { 'tecnico_n1' }
    end

    trait :tecnico_n2 do
      role { 'tecnico_n2' }
    end
  end
end
