require_relative "unii/version"
require_relative "unii/errors"
require_relative "unii/client"

module Unii
  def self.new(api_key:, base_url: "http://localhost:8080")
    Client.new(api_key: api_key, base_url: base_url)
  end
end
