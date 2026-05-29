class ChatwootConfig < ApplicationRecord
  belongs_to :workspace

  validates :chatwoot_url,        presence: true,
                                  format: { with: /\Ahttps?:\/\/.+/, message: "deve ser uma URL válida" }
  validates :chatwoot_account_id, presence: true
  validates :chatwoot_api_token,  presence: true

  # Criptografia do token via ActiveSupport::MessageEncryptor
  CIPHER_KEY = ActiveSupport::KeyGenerator.new(
    Rails.application.secret_key_base
  ).generate_key("chatwoot_token_encryption", 32)

  ENCRYPTOR = ActiveSupport::MessageEncryptor.new(CIPHER_KEY, cipher: "aes-256-cbc")

  def chatwoot_api_token=(raw)
    return if raw.blank?
    self[:chatwoot_api_token] = ENCRYPTOR.encrypt_and_sign(raw)
  end

  def chatwoot_api_token
    raw = self[:chatwoot_api_token]
    return nil if raw.blank?
    ENCRYPTOR.decrypt_and_verify(raw)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  # Retorna token em texto plano para uso no Chatwoot::Client
  def decrypted_token
    chatwoot_api_token
  end
end
