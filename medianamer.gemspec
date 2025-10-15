Gem::Specification.new do |spec|
  spec.name          = "medianamer"
  spec.version       = "0.1.0"
  spec.authors       = ["Ben Effiom"]
  spec.email         = ["beffiom@protonmail.com"]
  
  spec.summary       = "Rename media files for Plex/Jellyfin"
  spec.license       = "MIT"
  
  spec.files         = Dir["lib/**/*", "bin/*"]
  spec.bindir        = "bin"
  spec.executables   = ["medianamer"]
  spec.require_paths = ["lib"]
  
  spec.required_ruby_version = ">= 3.0"
  spec.add_dependency "dotenv", "~> 2.8"
  spec.add_dependency "logger", "~> 1.6"

end
