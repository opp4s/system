class TranscribeAudioJob < ApplicationJob
  queue_as :default

  WHISPER_URL     = ENV.fetch("WHISPER_URL", "http://zavy-whisper:8000")
  WHISPER_MODEL   = ENV.fetch("WHISPER_MODEL", "Systran/faster-whisper-small")
  AUDIO_TYPES     = %w[audio/ogg audio/mpeg audio/mp4 audio/aac audio/webm audio].freeze
  TIMEOUT_SECONDS = 120
  MAX_REDIRECTS   = 5

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    audio_att = message.attachments&.find { |a| AUDIO_TYPES.any? { |t| a["content_type"].to_s.include?(t) } }
    return unless audio_att

    audio_url = audio_att["url"]
    return if audio_url.blank?

    Rails.logger.info "[Whisper] Iniciando transcrição para message ##{message_id}: #{audio_url[0..60]}"

    tempfile = download_audio(audio_url)
    unless tempfile
      Rails.logger.warn "[Whisper] Falha ao baixar áudio para message ##{message_id}"
      return
    end

    transcription = transcribe(tempfile)
    unless transcription.present?
      Rails.logger.warn "[Whisper] Transcrição vazia para message ##{message_id}"
      return
    end

    message.update!(
      metadata: (message.metadata || {}).merge("transcription" => transcription)
    )
    Rails.logger.info "[Whisper] Transcrição concluída ##{message_id}: #{transcription[0..80]}..."
  rescue => e
    Rails.logger.error "[Whisper] TranscribeAudioJob falhou ##{message_id}: #{e.class}: #{e.message}"
  ensure
    tempfile&.close
    tempfile&.unlink
  end

  private

  # Segue redirects (Active Storage URLs do Chatwoot fazem 302)
  def download_audio(url, redirects_left = MAX_REDIRECTS)
    return nil if redirects_left == 0

    uri  = URI(url)
    resp = Net::HTTP.start(uri.host, uri.port,
                           use_ssl:      uri.scheme == "https",
                           open_timeout: 10,
                           read_timeout: 30) { |h| h.get(uri.request_uri) }

    case resp
    when Net::HTTPSuccess
      ext      = File.extname(uri.path).presence || ".ogg"
      tempfile = Tempfile.new(["audio", ext])
      tempfile.binmode
      tempfile.write(resp.body)
      tempfile.rewind
      tempfile
    when Net::HTTPRedirection
      location = resp["location"]
      Rails.logger.info "[Whisper] Seguindo redirect → #{location[0..60]}"
      download_audio(location, redirects_left - 1)
    else
      Rails.logger.warn "[Whisper] Download falhou com HTTP #{resp.code}"
      nil
    end
  rescue => e
    Rails.logger.warn "[Whisper] Falha ao baixar áudio #{url[0..60]}: #{e.message}"
    nil
  end

  def transcribe(tempfile)
    boundary = SecureRandom.hex(16)
    body     = build_multipart(boundary, tempfile)

    uri = URI("#{WHISPER_URL}/v1/audio/transcriptions")
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    req.body = body

    resp = Net::HTTP.start(uri.host, uri.port,
                           read_timeout: TIMEOUT_SECONDS,
                           open_timeout: 10) { |h| h.request(req) }

    unless resp.is_a?(Net::HTTPSuccess)
      Rails.logger.warn "[Whisper] API retornou #{resp.code}: #{resp.body[0..100]}"
      return nil
    end

    JSON.parse(resp.body)["text"].to_s.strip
  rescue => e
    Rails.logger.warn "[Whisper] Falha na transcrição: #{e.message}"
    nil
  end

  def build_multipart(boundary, tempfile)
    ext      = File.extname(tempfile.path).sub(".", "").presence || "ogg"
    ct       = { "ogg" => "audio/ogg", "mp3" => "audio/mpeg", "m4a" => "audio/mp4" }.fetch(ext, "audio/ogg")
    filename = "audio.#{ext}"

    body = +"".encode("ASCII-8BIT")

    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
    body << "Content-Type: #{ct}\r\n\r\n"
    body << tempfile.read.force_encoding("ASCII-8BIT")
    body << "\r\n"

    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"model\"\r\n\r\n#{WHISPER_MODEL}\r\n"

    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"language\"\r\n\r\npt\r\n"

    body << "--#{boundary}--\r\n"
    body
  end
end
