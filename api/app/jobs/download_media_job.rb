class DownloadMediaJob < ApplicationJob
  queue_as :default

  UPLOADS_DIR  = File.join(Rails.root, "public", "uploads")
  APP_URL      = ENV.fetch("APP_URL", "https://api.zavycrm.com")
  MAX_REDIRECTS = 5
  TIMEOUT       = 30

  EXTENSION_MAP = {
    "image/jpeg"     => "jpg",
    "image/png"      => "png",
    "image/webp"     => "webp",
    "image/gif"      => "gif",
    "audio/ogg"      => "ogg",
    "audio/mpeg"     => "mp3",
    "audio/mp4"      => "m4a",
    "video/mp4"      => "mp4",
    "application/pdf" => "pdf"
  }.freeze

  def perform(message_id, attachment_index = 0)
    message = Message.find_by(id: message_id)
    return unless message

    atts = message.attachments.dup
    att  = atts[attachment_index]
    return if att.blank?
    return if att["url"].to_s.start_with?(APP_URL)

    data = fetch_media_data(message, att)
    unless data.present?
      Rails.logger.warn "[DownloadMedia] Não foi possível obter mídia para message ##{message_id}"
      return
    end

    FileUtils.mkdir_p(UPLOADS_DIR)

    ext      = resolve_extension(att)
    filename = "#{SecureRandom.uuid}.#{ext}"
    path     = File.join(UPLOADS_DIR, filename)
    File.binwrite(path, data)

    public_url = "#{APP_URL}/uploads/#{filename}"

    atts[attachment_index] = att.except("base64").merge("url" => public_url)
    message.update_columns(attachments: atts)

    Rails.logger.info "[DownloadMedia] Salvo message ##{message_id}: #{public_url}"

    ct = att["content_type"].to_s
    if ct.start_with?("audio")
      TranscribeAudioJob.perform_later(message_id)
    end

  rescue => e
    Rails.logger.error "[DownloadMedia] Falhou message ##{message_id}: #{e.class}: #{e.message}"
  end

  private

  # Priority: 1) base64 already in attachment  2) URL download  3) Evolution getBase64
  def fetch_media_data(message, att)
    if att["base64"].present?
      return Base64.decode64(att["base64"])
    end

    url = att["url"].to_s
    if url.present?
      data = download_url(url)
      return data if data.present?
    end

    fetch_via_evolution(message)
  end

  def download_url(url, redirects_left = MAX_REDIRECTS)
    return nil if redirects_left == 0 || url.blank?

    uri  = URI(url)
    resp = Net::HTTP.start(uri.host, uri.port,
                           use_ssl:      uri.scheme == "https",
                           open_timeout: 10,
                           read_timeout: TIMEOUT) { |h| h.get(uri.request_uri) }

    case resp
    when Net::HTTPSuccess
      resp.body
    when Net::HTTPRedirection
      download_url(resp["location"], redirects_left - 1)
    else
      Rails.logger.warn "[DownloadMedia] URL download falhou HTTP #{resp.code}: #{url[0..60]}"
      nil
    end
  rescue => e
    Rails.logger.warn "[DownloadMedia] URL download erro: #{e.message}"
    nil
  end

  def fetch_via_evolution(message)
    return nil unless message.source_id.present? && message.sender_phone.present?

    wi = whatsapp_instance_for(message)
    return nil unless wi

    number    = message.sender_phone.gsub(/[^0-9]/, "")
    remote_jid = "#{number}@s.whatsapp.net"

    client = Whatsapp::EvolutionClient.new
    resp   = client.get_base64_from_media(
      wi.instance_id,
      message_id:  message.source_id,
      remote_jid:  remote_jid
    )

    b64 = resp&.dig("base64") || resp&.dig(:base64)
    return nil unless b64.present?

    b64_clean = b64.sub(/\Adata:[^;]+;base64,/, "")
    Base64.decode64(b64_clean)
  rescue => e
    Rails.logger.warn "[DownloadMedia] Evolution getBase64 falhou: #{e.message}"
    nil
  end

  def whatsapp_instance_for(message)
    return nil unless message.card_id.present?
    card = message.card
    return nil unless card&.pipeline_id.present?
    WhatsappInstance.find_by(workspace: message.workspace, pipeline_id: card.pipeline_id)
  end

  def resolve_extension(att)
    ct = att["content_type"].to_s.split(";").first.strip
    EXTENSION_MAP[ct] || File.extname(att["filename"].to_s).delete(".").presence || "bin"
  end
end
