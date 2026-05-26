module WhatsappLite
  class DownloadMediaJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    # Chatwoot Attachment.file_types: image, audio, video, file
    FILE_TYPE_MAP = {
      'image'    => 'image',
      'audio'    => 'audio',
      'video'    => 'video',
      'document' => 'file',
      'sticker'  => 'image'  # stickers são imagens (webp)
    }.freeze

    EXT_MAP = {
      'image'    => 'jpg',
      'audio'    => 'ogg',
      'video'    => 'mp4',
      'document' => 'bin',
      'sticker'  => 'webp'
    }.freeze

    CONTENT_TYPE_MAP = {
      'image'    => 'image/jpeg',
      'audio'    => 'audio/ogg',
      'video'    => 'video/mp4',
      'document' => 'application/octet-stream',
      'sticker'  => 'image/webp'
    }.freeze

    def perform(message_id, media_url, media_type, instance_id)
      message = Message.find_by(id: message_id)
      return unless message

      creds   = WhatsappLite::AccountHelpers.credentials_for(message.account)
      api_key = creds['evolution_api_key'] || ENV['EVOLUTION_API_KEY']

      require 'faraday/follow_redirects'
      conn = Faraday.new do |f|
        f.response :follow_redirects
        f.options.timeout      = 60  # vídeos podem ser grandes
        f.options.open_timeout = 10
      end

      response = conn.get(media_url) do |req|
        req.headers['apikey'] = api_key if api_key
      end

      return unless response.success?

      content_type = response.headers['content-type']&.split(';')&.first ||
                     CONTENT_TYPE_MAP.fetch(media_type, 'application/octet-stream')

      ext       = EXT_MAP.fetch(media_type, 'bin')
      file_type = FILE_TYPE_MAP.fetch(media_type, 'file')
      filename  = "wl_#{media_type}_#{message_id}.#{ext}"

      attachment = message.attachments.new(
        account_id: message.account_id,
        file_type:  file_type,
        file: {
          io:           StringIO.new(response.body),
          filename:     filename,
          content_type: content_type
        }
      )
      attachment.save!

      Rails.logger.tagged('whatsapp_lite', 'media') do
        Rails.logger.info "downloaded #{media_type} (#{response.body.bytesize} bytes) for message_id=#{message_id}"
      end
    end
  end
end
