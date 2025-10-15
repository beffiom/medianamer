# frozen_string_literal: true

require 'fileutils'

module MediaNamer
  # Renames files and updates metadata
  class FileRenamer
    def rename(episode, new_title, dry_run: false)
      old_path = episode[:path]
      extension = File.extname(old_path)
      directory = File.dirname(old_path)
      
      season = episode[:season].to_s.rjust(2, '0')
      ep_num = episode[:episode].to_s.rjust(2, '0')
      
      new_filename = "S#{season}E#{ep_num} #{sanitize(new_title)}#{extension}"
      new_path = File.join(directory, new_filename)

      if old_path == new_path
        puts "      Already correct: #{new_filename}"
        return old_path
      end
      
      if dry_run
        puts "      Would rename: #{File.basename(old_path)} → #{new_filename}"
      else
        FileUtils.mv(old_path, new_path)
        puts "      Renamed: #{new_filename}"
      end
      
      new_path
    end

    private

    def sanitize(title)
      # Remove invalid filename characters
      title.gsub(/[<>:"|?*\/\\]/, '').strip
    end
  end
end
