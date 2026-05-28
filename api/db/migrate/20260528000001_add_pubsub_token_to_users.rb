class AddPubsubTokenToUsers < ActiveRecord::Migration[7.1]
  def up
    add_column :users, :pubsub_token, :string
    add_index  :users, :pubsub_token, unique: true

    User.find_each do |u|
      u.update_columns(pubsub_token: SecureRandom.hex(32))
    end

    change_column_null :users, :pubsub_token, false
  end

  def down
    remove_column :users, :pubsub_token
  end
end
