require "minitest/autorun"
require_relative "../lib/unii"

class TestUniiClient < Minitest::Test
  def test_requires_api_key
    assert_raises(Unii::Error) { Unii::Client.new(api_key: nil) }
    assert_raises(Unii::Error) { Unii::Client.new(api_key: "   ") }
  end

  def test_initializes_with_valid_key
    client = Unii::Client.new(api_key: "test_key", base_url: "http://localhost:8080/")
    assert_equal "test_key", client.api_key
    assert_equal "http://localhost:8080", client.base_url
  end
end
