class MakeChatwootContactIdOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :contacts, :chatwoot_contact_id, true
  end
end
