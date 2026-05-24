class WhatsappLiteChannel < ApplicationRecord
  belongs_to :account
  belongs_to :inbox

  enum :status, { disconnected: 0, qr_pending: 1, connected: 2 }

  validates :instance_id,  presence: true, uniqueness: true
  validates :phone_number, presence: true

  # Savepoint evita que RecordNotUnique envenene a transacao PostgreSQL externa.
  # Sem savepoint: PG marca a transacao como abortada e queries subsequentes falham.
  def self.find_or_create_race_safe!(instance_id:, account_id:, phone_number:, inbox:)
    transaction(requires_new: true) do
      find_or_create_by!(instance_id: instance_id) do |c|
        c.account_id   = account_id
        c.phone_number = phone_number
        c.inbox        = inbox
      end
    end
  rescue ActiveRecord::RecordNotUnique
    find_by!(instance_id: instance_id)
  end
end
