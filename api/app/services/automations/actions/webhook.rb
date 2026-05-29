module Automations
  module Actions
    class Webhook
      def self.run(card, config)
        url = config["url"]
        method = config["method"] || "POST"
        headers = config["headers"] || { "Content-Type" => "application/json" }
        
        payload = {
          card: card.as_json(only: [:id, :title, :value, :contact_name, :contact_phone]),
          event: "automation_triggered",
          workspace_id: card.workspace_id,
          timestamp: Time.current.iso8601
        }
        
        begin
          conn = Faraday.new(url: url, headers: headers)
          response = case method.upcase
                     when "GET"
                       conn.get(url)
                     when "PUT"
                       conn.put(url) { |req| req.body = payload.to_json }
                     when "PATCH"
                       conn.patch(url) { |req| req.body = payload.to_json }
                     when "DELETE"
                       conn.delete(url)
                     else # POST
                       conn.post(url) { |req| req.body = payload.to_json }
                     end
          
          success = response.status >= 200 && response.status < 300
          
          { 
            success: success, 
            type: "webhook", 
            url: url, 
            status: response.status 
          }
        rescue => e
          { success: false, type: "webhook", url: url, error: e.message }
        end
      end
    end
  end
end
