module Unii
  class Error < StandardError; end

  class ApiError < Error
    attr_reader :status, :body

    def initialize(status:, message:, body: nil)
      super("HTTP #{status}: #{message}")
      @status = status
      @body = body
    end
  end
end
