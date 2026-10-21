Gem::Specification.new do |spec|
  spec.name          = "unii"
  spec.version       = "0.1.0"
  spec.authors       = ["Unii Team"]
  spec.email         = ["dev@unii.dev"]
  spec.summary       = "Official Ruby SDK for Unii conversational AI platform"
  spec.homepage      = "https://github.com/malviys/unii"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]
end
