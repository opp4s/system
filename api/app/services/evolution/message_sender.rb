module Evolution
  class MessageSender
    class SendError < StandardError; end

    AUDIO_TYPES    = %w[audio/ogg audio/mpeg audio/mp4 audio/aac audio/webm].freeze
    IMAGE_TYPES    = %w[image/png image/jpeg image/jpg image/webp image/gif].freeze
    VIDEO_TYPES    = %w[video/mp4 video/quicktime].freeze

    def initialize(instance, card, user, content:, attachment: nil, in_reply_to: nil)
      @instance    = instance
      @card        = card
      @user        = user
      @content     = content.to_s.strip
      @attachment  = attachment
      @in_reply_to = in_reply_to
    end

    # Returns the persisted Message record.
    def call
      number = @card.contact_phone.to_s.gsub(/[^0-9]/, "")
      raise SendError, "Card sem telefone de contato" if number.blank?

      quoted_id  = resolve_quoted_source_id
      evo_client = Whatsapp::EvolutionClient.new

      evo_resp = if @attachment
        send_attachment(evo_client, number, quoted_id)
      else
        evo_client.send_text(@instance.instance_id, number, @content, quoted_source_id: quoted_id)
      end

      source_id = extract_source_id(evo_resp)

      meta = {}
      meta["in_reply_to"] = @in_reply_to.to_s if @in_reply_to.present?

      Message.create!(
        workspace:    @card.workspace,
        card:         @card,
        contact:      find_contact,
        source_id:    source_id,
        content:      @content.presence || @attachment&.original_filename || "",
        message_type: "outgoing",
        channel:      "whatsapp",
        sender_name:  @user.name,
        attachments:  @attachment ? [build_attachment_meta] : [],
        metadata:     meta
      )
    rescue Whatsapp::EvolutionClient::ApiError => e
      raise SendError, "Evolution API: #{e.message}"
    end

    private

    def send_attachment(evo_client, number, quoted_id)
      ct   = @attachment.content_type.to_s
      data = Base64.strict_encode64(@attachment.read)
      @attachment.rewind

      if AUDIO_TYPES.any? { |t| ct.start_with?(t) }
        evo_client.send_audio(@instance.instance_id, number, data, quoted_source_id: quoted_id)
      elsif VIDEO_TYPES.any? { |t| ct.start_with?(t) }
        evo_client.send_media(@instance.instance_id, number, data, "video",
                              caption: @content, quoted_source_id: quoted_id)
      elsif IMAGE_TYPES.any? { |t| ct.start_with?(t) }
        evo_client.send_media(@instance.instance_id, number, data, "image",
                              caption: @content, quoted_source_id: quoted_id)
      else
        evo_client.send_media(@instance.instance_id, number, data, "document",
                              caption:           @content,
                              filename:          @attachment.original_filename,
                              quoted_source_id:  quoted_id)
      end
    end

    # Resolves in_reply_to to an Evolution source_id string.
    def resolve_quoted_source_id
      return nil if @in_reply_to.blank?

      if @in_reply_to.to_s =~ /\A\d+\z/
        msg = Message.find_by(id: @in_reply_to.to_i)
        return msg&.source_id
      end

      @in_reply_to.to_s
    end

    def extract_source_id(resp)
      return nil if resp.nil?
      resp.dig("key", "id") || resp.dig(:key, :id)
    end

    def find_contact
      @card.workspace.contacts.find_by(phone_number: @card.contact_phone)
    end

    def build_attachment_meta
      {
        "filename"     => @attachment.original_filename,
        "content_type" => @attachment.content_type,
        "size"         => @attachment.size
      }
    end
  end
end
