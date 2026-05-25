class WhatsappLiteChannel < ApplicationRecord
  belongs_to :account
  belongs_to :inbox

  enum :status, {
    auto_disconnected: 0,
    qr_pending:        1,
    connected:         2,
    user_disconnected: 3,
    deleted:           4
  }

  scope :visible,       -> { where.not(status: :deleted) }
  scope :reconnectable, -> { where(status: %i[auto_disconnected user_disconnected]) }

  validates :instance_id,  presence: true, uniqueness: true
  validates :phone_number, presence: true

  def display_status
    {
      auto_disconnected: { label: 'Desconectado',  color: 'red'    },
      qr_pending:        { label: 'Aguardando QR', color: 'orange' },
      connected:         { label: 'Conectado',     color: 'green'  },
      user_disconnected: { label: 'Desconectado',  color: 'violet' },
      deleted:           { label: 'Excluído',      color: 'gray'   }
    }[status.to_sym]
  end

  # Savepoint evita que RecordNotUnique envenene a transacao PostgreSQL externa.
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
