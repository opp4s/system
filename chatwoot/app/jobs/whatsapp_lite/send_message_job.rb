module WhatsappLite
  class SendMessageJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(message_id)
      message = Message.find_by(id: message_id)
      return unless message

      channel = WhatsappLiteChannel.find_by(inbox_id: message.inbox_id)
      return unless channel&.connected?

      contact_phone = message.conversation&.contact&.phone_number
      return unless contact_phone.present?

      creds    = WhatsappLite::AccountHelpers.credentials_for(message.account)
      api_url  = creds['evolution_api_url'] || ENV['EVOLUTION_API_URL']
      api_key  = creds['evolution_api_key'] || ENV['EVOLUTION_API_KEY']

      raise WhatsappLite::EvolutionApiError, 'Evolution API não configurada' unless api_url && api_key

      conn = Faraday.new(url: api_url) do |f|
        f.options.timeout      = 15
        f.options.open_timeout = 5
        f.response :raise_error
      end

      number = contact_phone.gsub(/\D/, '')

      resp = conn.post("/message/sendText/#{channel.instance_id}") do |req|
        req.headers['apikey']       = api_key
        req.headers['Content-Type'] = 'application/json'
        req.body = { number: number, text: message.content }.to_json
      end

      # Persist Evolution message ID so webhook_controller can skip the echo-back.
      if resp.body.present?
        resp_data = JSON.parse(resp.body, symbolize_names: true) rescue {}
        evolution_id = resp_data.dig(:key, :id) || resp_data[:id]
        message.update_column(:source_id, evolution_id) if evolution_id.present?
      end

      Rails.logger.tagged('whatsapp_lite', 'send') do
        Rails.logger.info "message_id=#{message_id} instance=#{channel.instance_id} phone=#{number} enviado"
      end
    rescue Faraday::Error, WhatsappLite::EvolutionApiError => e
      Rails.logger.tagged('whatsapp_lite', 'send') do
        Rails.logger.error "message_id=#{message_id} falhou: #{e.message}"
      end
      message&.update_column(:status, Message.statuses[:failed])
      raise
    end
  end
end
