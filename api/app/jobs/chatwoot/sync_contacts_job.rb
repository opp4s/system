module Chatwoot
  class SyncContactsJob < ApplicationJob
    queue_as :default

    PER_PAGE = 100

    def perform(workspace_id)
      workspace = Workspace.find_by(id: workspace_id)
      return unless workspace

      config = workspace.chatwoot_config
      return unless config

      client    = ::Chatwoot::Client.new(config)
      page      = 1
      synced    = 0

      loop do
        result   = client.contacts(page: page, include_contacts: true)
        contacts = result[:payload] || []
        break if contacts.empty?

        contacts.each do |cw|
          upsert_contact(workspace, cw)
          synced += 1
        end

        meta       = result[:meta] || {}
        total      = meta[:count].to_i
        break if synced >= total || contacts.length < PER_PAGE
        page += 1
      end

      Rails.logger.info "[SyncContactsJob] workspace=#{workspace_id} synced=#{synced}"
      synced
    end

    private

    def upsert_contact(workspace, cw)
      contact = Contact.find_or_initialize_by(
        workspace:            workspace,
        chatwoot_contact_id:  cw[:id].to_i
      )

      contact.assign_attributes(
        name:                  cw[:name].presence || "Sem nome",
        email:                 cw[:email].presence,
        phone_number:          cw[:phone_number].presence,
        avatar_url:            cw[:thumbnail].presence,
        additional_attributes: cw[:additional_attributes] || {},
        custom_attributes:     cw[:custom_attributes] || {},
        chatwoot_created_at:   parse_time(cw[:created_at]),
        last_synced_at:        Time.current
      )

      contact.save!
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "[SyncContactsJob] Skipping cw_contact #{cw[:id]}: #{e.message}"
    end

    def parse_time(val)
      return nil if val.blank?
      val.is_a?(Numeric) ? Time.at(val) : Time.parse(val.to_s)
    rescue ArgumentError
      nil
    end
  end
end
