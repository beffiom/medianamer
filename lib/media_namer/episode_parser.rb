# frozen_string_literal: true

module MediaNamer
  # Parses episode information from directory structure
  class EpisodeParser
    def parse(files)
      episodes_by_season = group_by_season(files)
      
      episodes_by_season.flat_map do |season, season_files|
        next [] if season.nil?
        
        season_files.sort.each_with_index.map do |file, index|
          {
            path: file,
            season: season,
            episode: index + 1,  # Restarts at 1 for each season
            original_name: File.basename(file)
          }
        end
      end.compact
    end

    private

    def group_by_season(files)
      files.group_by { |file| extract_season(file) }
    end

    def extract_season(file)
      # Check for "Specials" folder
      return 0 if file.match?(/Specials/i)
  
      # Match "Season X" pattern
      match = file.match(/Season\s+(\d+)/i)
      return nil unless match
  
      match[1].to_i
    end
  end
end
