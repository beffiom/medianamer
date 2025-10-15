# frozen_string_literal: true

module MediaNamer
  # Scans directories for video files grouped by series
  class FileScanner
    VIDEO_EXTENSIONS = %w[.mkv .mp4 .avi .mov .m4v].freeze

    def scan(base_directory)
      # Check if this is a single show directory (contains Season folders)
      if single_show?(base_directory)
        show_name = File.basename(base_directory)
        files = find_videos_in(base_directory)
        return { show_name => files } if files.any?
      end
      
      # Otherwise scan for multiple shows
      scan_multiple_shows(base_directory)
    end

    private

    def single_show?(directory)
      Dir.glob(File.join(directory, '*')).any? do |item|
        File.directory?(item) && File.basename(item).match?(/Season\s+\d+/i)
      end
    end

    def scan_multiple_shows(base_directory)
      series = {}
      
      Dir.glob(File.join(base_directory, '*')).each do |series_dir|
        next unless File.directory?(series_dir)
        
        series_name = File.basename(series_dir)
        files = find_videos_in(series_dir)
        
        series[series_name] = files if files.any?
      end
      
      series
    end

    def find_videos_in(directory)
      Dir.glob(File.join(directory, '**', '*'))
         .select { |f| File.file?(f) && video_file?(f) }
    end

    def video_file?(path)
      VIDEO_EXTENSIONS.include?(File.extname(path).downcase)
    end
  end
end
