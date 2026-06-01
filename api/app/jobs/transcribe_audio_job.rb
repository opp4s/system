class TranscribeAudioJob < ApplicationJob
  queue_as :default

  WHISPER_URL     = ENV.fetch("WHISPER_URL", "http://zavy-whisper:8000")
  AUDIO_TYPES     = %w[audio/ogg audio/mpeg audio/mp4 audio/aac audio/webm].freeze
  TIMEOUT_SECONDS = 120

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    audio_att = message.attachments&.find { |a| AUDIO_TYPES.include?(a["content_type"].to_s) }
    return unless audio_att

    audio_url = audio_att["url"]
    return if audio_url.blank?

    tempfile = download_audio(audio_url)
    return unless tempfile

    transcription = transcribe(tempfile)
    return if transcription.blank?

    message.update!(
      metadata: (message.metadata || {}).merge("transcription" => transcription)
    )
    Rails.logger.info "[Whisper] Transcrição concluída para message ##{message_id}: #{transcription[0..80]}..."
  rescue => e
    Rails.logger.error "[Whisper] TranscribeAudioJob falhou para message ##{message_id}: #{e.message}"
  ensure
    tempfile&.close
    tempfile&.unlink
  end

  private

  def download_audio(url)
    uri  = URI(url)
    resp = Net::HTTP.start(uri.host, uri.port,
                           use_ssl:      uri.scheme == "https",
                           read_timeout: 30) { |h| h.get(uri.request_uri) }
    return nil unless resp.is_a?(Net::HTTPSuccess)

    ext      = File.extname(uri.path).presence || ".ogg"
    tempfile = Tempfile.new(["audio", ext], binmode: true)
    tempfile.write(resp.body)
    tempfile.rewind
    tempfile
  rescue => e
    Rails.logger.warn "[Whisper] Falha ao baixar áudio #{url}: #{e.message}"
    nil
  end

  def transcribe(tempfile)
    boundary = SecureRandom.hex(16)
    body     = build_multipart(boundary, tempfile)

    uri = URI("#{WHISPER_URL}/v1/audio/transcriptions")
    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    req.body = body

    resp = Net::HTTP.start(uri.host, uri.port, read_timeout: TIMEOUT_SECONDS) { |h| h.request(req) }
    JSON.parse(resp.body)["text"].to_s.strip
  rescue => e
    Rails.logger.warn "[Whisper] Falha na transcrição: #{e.message}"
    nil
  end

  def build_multipart(boundary, tempfile)
    ext      = File.extname(tempfile.path).sub(".", "")
    ct       = ext == "ogg" ? "audio/ogg" : "audio/mpeg"
    filename = "audio.#{ext}"

    body = +"".encode("ASCII-8BIT")
    # campo file
    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
    body << "Content-Type: #{ct}\r\n\r\n"
    body << tempfile.read.force_encoding("ASCII-8BIT")
    body << "\r\n"
    # campo language
    body << "--#{boundary}\r\n"
    body << "Content-Disposition: form-data; name=\"language\"\r\n\r\npt\r\n"
    body << "--#{boundary}--\r\n"
    body
  end
end
