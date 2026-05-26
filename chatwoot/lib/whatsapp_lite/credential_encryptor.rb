module WhatsappLite
  module CredentialEncryptor
    ENCRYPTED_FIELDS = %w[evolution_api_key evolution_webhook_token].freeze
    ENCRYPTION_PREFIX = 'enc:'.freeze

    module_function

    def encryptor
      @encryptor ||= begin
        key = encryption_key
        ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm')
      end
    end

    def encryption_key
      # Usa variável de ambiente dedicada, ou deriva do SECRET_KEY_BASE
      raw = ENV['WHATSAPP_LITE_ENCRYPTION_KEY'] || Rails.application.secret_key_base
      ActiveSupport::KeyGenerator.new(raw).generate_key('whatsapp_lite_credentials', 32)
    end

    # Encripta um hash de credenciais (apenas campos sensíveis)
    def encrypt_credentials(creds)
      return creds unless creds.is_a?(Hash)

      creds.each_with_object({}) do |(key, value), result|
        if ENCRYPTED_FIELDS.include?(key.to_s) && value.present? && !encrypted?(value)
          result[key.to_s] = "#{ENCRYPTION_PREFIX}#{encryptor.encrypt_and_sign(value)}"
        else
          result[key.to_s] = value
        end
      end
    end

    # Decripta um hash de credenciais (apenas campos com prefixo enc:)
    def decrypt_credentials(creds)
      return creds unless creds.is_a?(Hash)

      creds.each_with_object({}) do |(key, value), result|
        if encrypted?(value)
          result[key.to_s] = encryptor.decrypt_and_verify(value.sub(ENCRYPTION_PREFIX, ''))
        else
          result[key.to_s] = value
        end
      rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
        Rails.logger.tagged('whatsapp_lite', 'crypto') do
          Rails.logger.error "failed to decrypt #{key}: #{e.message}"
        end
        result[key.to_s] = nil
      end
    end

    def encrypted?(value)
      value.is_a?(String) && value.start_with?(ENCRYPTION_PREFIX)
    end

    # Migra credenciais plaintext → encrypted para uma account
    def encrypt_account!(account)
      creds = account.settings&.dig('whatsapp_lite')
      return unless creds.is_a?(Hash)

      encrypted = encrypt_credentials(creds)
      return if encrypted == creds # já encriptado

      new_settings = account.settings.merge('whatsapp_lite' => encrypted)
      account.update!(settings: new_settings)
      encrypted
    end

    # Migra TODAS as accounts
    def encrypt_all!
      Account.where("settings->'whatsapp_lite' IS NOT NULL").find_each do |account|
        result = encrypt_account!(account)
        if result
          Rails.logger.info "[whatsapp_lite] Encrypted credentials for account #{account.id}"
        end
      end
    end
  end
end
