class Channel::WhatsappLite < ApplicationRecord
  include Channelable

  self.table_name = 'channel_whatsapp_lite'

  EDITABLE_ATTRS = [].freeze

  def name
    'WhatsApp Lite'
  end

  # Chatwoot chama messaging_window_enabled? em alguns channels.
  # WhatsApp não tem janela de messaging obrigatória neste contexto.
  def messaging_window_enabled?
    false
  end
end
