class AddSourceIdToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :source_id, :string
    add_index  :messages, [:workspace_id, :source_id],
               where: "source_id IS NOT NULL"
  end
end
