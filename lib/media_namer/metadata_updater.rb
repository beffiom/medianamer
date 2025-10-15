# frozen_string_literal: true

module MediaNamer
  # Updates video file metadata using ffmpeg
  class MetadataUpdater
    def update(file_path, title, dry_run: false)
      unless ffmpeg_installed?
        puts "      ⚠ ffmpeg not installed, skipping metadata update"
        return
      end

      if dry_run
        puts "      Would update metadata: title='#{title}'"
      else
        update_metadata(file_path, title)
        puts "      Updated metadata"
      end
    end

    private

    def ffmpeg_installed?
      system('which ffmpeg > /dev/null 2>&1')
    end

    def update_metadata(file_path, title)
      ext = File.extname(file_path)
      temp_file = file_path.sub(/#{Regexp.escape(ext)}$/, "_tmp#{ext}")
      
      command = [
        'ffmpeg',
        '-i', file_path,
        '-c', 'copy',
        '-metadata', "title=#{title}",
        temp_file,
        '-y'
      ]
      
      success = system(*command, out: File::NULL, err: File::NULL)
      
      unless success
        puts "      ⚠ ffmpeg failed"
        File.delete(temp_file) if File.exist?(temp_file)
        return
      end
      
      FileUtils.mv(temp_file, file_path)
    end
  end
end
