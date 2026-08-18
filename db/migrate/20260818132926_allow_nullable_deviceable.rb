# frozen_string_literal: true

class AllowNullableDeviceable < ActiveRecord::Migration[7.2]
  def change
    change_column_null :devices, :deviceable_type, true
    change_column_null :devices, :deviceable_id, true
  end
end
