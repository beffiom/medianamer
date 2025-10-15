require 'dotenv/load'
require_relative 'media_namer/cli'
require_relative 'media_namer/file_scanner'
require_relative 'media_namer/episode_parser'
require_relative 'media_namer/file_renamer'
require_relative 'media_namer/metadata_updater'
require_relative 'media_namer/logger'
require_relative 'media_namer/api/tmdb'

module MediaNamer
  VERSION = "0.1.0"
end
