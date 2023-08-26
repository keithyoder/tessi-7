# frozen_string_literal: true

json.extract! nf21_item, :id, :nf_21, :references, :item, :text, :created_at, :updated_at
json.url nf21_item_url(nf21_item, format: :json)
