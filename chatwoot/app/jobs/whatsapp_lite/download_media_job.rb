module WhatsappLite
  class DownloadMediaJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    FILE_TYPE_MAP = {
      'image'    => 'image',
      'audio'    => 'audio',
      'document' => 'file'
    }.freeze

    EXT_MAP = {
      'image'    => 'jpg',
      'audio'    => 'ogg',
      'document' => 'bin'
    }.freeze

    def perform(message_id, media_url, media_type, instance_id)
      message = Message.find_by(id: message_id)
      return unless message

      settings = message.account.settings.dig('whatsapp_lite') || {}
      api_key  = settings['evolution_api_key'] || ENV['EVOLUTION_API_KEY']

      require 'faraday/follow_redirects'
      conn = Faraday.new do |f|
        f.response :follow_redirects
        f.options.timeout      = 30
        f.options.open_timeout = 10
      end

      response = conn.get(media_url) do |req|
        req.headers['apikey'] = api_key if api_key
      end

      return unless response.success?

      content_type = response.headers['content-type']&.split(';')&.first ||
                     case media_type
                     when 'image'    then 'image/jpeg'
                     when 'audio'    then 'audio/ogg'
                     when 'document' then 'application/octet-stream'
                     else 'application/octet-stream'
                     end

      ext          = EXT_MAP.fetch(media_type, 'bin')
      file_type    = FILE_TYPE_MAP.fetch(media_type, 'file')
      filename     = "wl_media_#{message_id}.#{ext}"

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
        Rails.logger.info "downloaded #{media_type} for message_id=#{message_id}"
      end
    end
  end
end
