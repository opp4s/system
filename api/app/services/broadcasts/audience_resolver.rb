module Broadcasts
  class AudienceResolver
    def initialize(broadcast)
      @broadcast = broadcast
      @workspace = broadcast.workspace
      @filters   = broadcast.audience_filters
    end

    def resolve
      contacts = @workspace.contacts.where.not(phone_number: [nil, ""])

      if @filters["stage_ids"].present?
        contacts = contacts.where(id: contacts_for_stages)
      end

      if @filters["pipeline_id"].present?
        contacts = contacts.where(id: contacts_for_pipeline)
      end

      contacts
    end

    def count
      resolve.count
    end

    private

    def contacts_for_stages
      phones = Card.active
                   .where(stage_id: @filters["stage_ids"], workspace: @workspace)
                   .pluck(:contact_phone)
                   .compact.uniq.reject(&:blank?)
      @workspace.contacts.where(phone_number: phones).pluck(:id)
    end

    def contacts_for_pipeline
      phones = Card.active
                   .where(pipeline_id: @filters["pipeline_id"], workspace: @workspace)
                   .pluck(:contact_phone)
                   .compact.uniq.reject(&:blank?)
      @workspace.contacts.where(phone_number: phones).pluck(:id)
    end
  end
end
