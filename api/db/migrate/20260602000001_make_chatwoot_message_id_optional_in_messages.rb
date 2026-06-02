class MakeChatwootMessageIdOptionalInMessages < ActiveRecord::Migration[7.1]
  def change
    change_column_null :messages, :chatwoot_message_id, true
  end
end
