class AddUserDisconnectedAndDeletedToWhatsappLiteChannels < ActiveRecord::Migration[7.1]
  def change
    # Não altera o tipo da coluna status — valores 0/1/2 preservados
    # Adiciona deleted_at para soft-delete e índices de performance
    add_column :whatsapp_lite_channels, :deleted_at, :datetime
    add_index :whatsapp_lite_channels, :deleted_at
    add_index :whatsapp_lite_channels, :status
  end
end
