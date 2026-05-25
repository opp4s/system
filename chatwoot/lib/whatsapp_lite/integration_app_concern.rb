module WhatsappLite
  module IntegrationAppConcern
    extend ActiveSupport::Concern

    def enabled?(account)
      return super unless id == 'whatsapp_lite'
      return super unless account

      WhatsappLiteChannel.where(account_id: account.id).visible.exists?
    end
  end
end
