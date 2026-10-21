require "net/http"
require "uri"
require "json"

module Unii
  class Client
    attr_reader :api_key, :base_url

    def initialize(api_key:, base_url: "http://localhost:8080")
      if api_key.nil? || api_key.to_s.strip.empty?
        raise Unii::Error, "api_key is required and must not be empty"
      end

      @api_key = api_key.to_s.strip
      @base_url = base_url.to_s.chomp("/")
    end

    def verify_auth
      uri = URI("#{@base_url}/api/v1/auth/verify")
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@api_key}"
      req["User-Agent"] = "unii-ruby-sdk/0.1.0"

      res = send_request(uri, req)
      JSON.parse(res.body)
    end

    def create_chat_completion(messages:, stream: false, temperature: nil, max_tokens: nil, project_id: nil)
      path = "/api/v1/chat/completions"
      path += "?projectId=#{project_id}" if project_id

      uri = URI("#{@base_url}#{path}")
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{@api_key}"
      req["Content-Type"] = "application/json"
      req["User-Agent"] = "unii-ruby-sdk/0.1.0"

      payload = {
        messages: format_messages(messages),
        stream: stream
      }
      payload[:temperature] = temperature unless temperature.nil?
      payload[:max_tokens] = max_tokens unless max_tokens.nil?

      req.body = JSON.generate(payload)

      res = send_request(uri, req)
      JSON.parse(res.body)
    end

    def stream_chat_completion(messages:, temperature: nil, max_tokens: nil, project_id: nil, &block)
      return enum_for(:stream_chat_completion, messages: messages, temperature: temperature, max_tokens: max_tokens, project_id: project_id) unless block_given?

      path = "/api/v1/chat/completions?stream=true"
      path += "&projectId=#{project_id}" if project_id

      uri = URI("#{@base_url}#{path}")
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{@api_key}"
      req["Content-Type"] = "application/json"
      req["Accept"] = "text/event-stream"
      req["User-Agent"] = "unii-ruby-sdk/0.1.0"

      payload = {
        messages: format_messages(messages),
        stream: true
      }
      payload[:temperature] = temperature unless temperature.nil?
      payload[:max_tokens] = max_tokens unless max_tokens.nil?
      req.body = JSON.generate(payload)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      http.request(req) do |res|
        unless res.is_a?(Net::HTTPSuccess)
          raise Unii::ApiError.new(status: res.code.to_i, message: res.message, body: res.body)
        end

        res.read_body do |chunk|
          chunk.each_line do |line|
            line = line.strip
            next if line.empty? || !line.start_with?("data:")

            data = line.sub(/^data:\s*/, "")
            break if data == "[DONE]"

            begin
              parsed = JSON.parse(data)
              yield parsed
            rescue JSON::ParserError
              next
            end
          end
        end
      end
    end

    private

    def send_request(uri, req)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      res = http.request(req)

      unless res.is_a?(Net::HTTPSuccess)
        msg = begin
          parsed = JSON.parse(res.body)
          parsed["message"] || parsed["error"] || res.message
        rescue StandardError
          res.message
        end
        raise Unii::ApiError.new(status: res.code.to_i, message: msg, body: res.body)
      end

      res
    end

    def format_messages(messages)
      messages.map do |m|
        if m.is_a?(Hash)
          { role: m[:role] || m["role"], content: m[:content] || m["content"] }
        else
          { role: m.role, content: m.content }
        end
      end
    end
  end
end
