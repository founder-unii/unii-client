Gem::Specification.new do |spec|
  spec.name          = "unii"
  spec.version       = "0.1.0"
  spec.authors       = ["Unii Team"]
  spec.email         = ["dev@getunii.com"]
  spec.summary       = "Official Ruby SDK for Unii conversational AI platform"
  spec.description   = "Official Ruby SDK for Unii conversational AI platform, supporting completions and streaming."
  spec.homepage      = "https://github.com/unii-founder/unii-client"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/unii-founder/unii-client"
  spec.metadata["bug_tracker_uri"] = "https://github.com/unii-founder/unii-client/issues"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]
end
