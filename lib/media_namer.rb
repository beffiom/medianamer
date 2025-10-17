# frozen_string_literal: true

require 'dotenv'

config_locations = [
  File.join(Dir.home, '.config', 'medianamer', '.env'),
  File.join(Dir.home, '.medianamer'),
  '.env'
]

config_file = config_locations.find { |path| File.exist?(path) }
Dotenv.load(config_file) if config_file

require_relative 'media_namer/cli'
require_relative 'media_namer/file_scanner'
require_relative 'media_namer/episode_parser'
require_relative 'media_namer/file_renamer'
require_relative 'media_namer/metadata_updater'
require_relative 'media_namer/logger'
require_relative 'media_namer/api/tmdb'

module MediaNamer
  VERSION = '0.1.0'
end
