# frozen_string_literal: true

class AddConfirmableToDevise < ActiveRecord::Migration[5.2]
  # NOTE: You can't use change, as User.update_all will fail in the down migration
  def up
    change_table :users, bulk: true do |t|
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email # Only if using reconfirmable
      t.index :confirmation_token, unique: true
    end
    # User.reset_column_information # Need for some types of updates, but not for update_all.
    # To avoid a short time window between running the migration and updating all existing
    # users as confirmed, do the following
    # rubocop:disable Rails/SkipsModelValidations
    User.update_all confirmed_at: DateTime.now
    # rubocop:enable Rails/SkipsModelValidations
    # All existing user accounts should be able to log in after this.
  end

  def down
    change_table :users, bulk: true do |t|
      t.remove :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
    end
  end
end
