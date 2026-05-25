module WhatsappLite
  module AccountHelpers
    module_function

    def primary_account_id
      ENV.fetch('WHATSAPP_LITE_PRIMARY_ACCOUNT_ID', '1').to_i
    end

    def primary_account
      Account.find_by(id: primary_account_id)
    end

    def primary?(account)
      account&.id == primary_account_id
    end

    # Returns Evolution credentials from the primary account.
    # All tenants (including primary) read from the same source.
    def credentials_for(_account)
      primary = primary_account
      return {} unless primary

      primary.settings&.dig('whatsapp_lite') || {}
    end
  end
end
