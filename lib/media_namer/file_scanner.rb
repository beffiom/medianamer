# frozen_string_literal: true

module MediaNamer
  # Scans directories for video files grouped by series
  class FileScanner
    VIDEO_EXTENSIONS = %w[.mkv .mp4 .avi .mov .m4v].freeze

  def scan(base_directory)
    series = {}
    
    Dir.glob(File.join(base_directory, '*')).each do |series_dir|
      next unless File.directory?(series_dir)
      
      series_name = File.basename(series_dir)
      files = find_videos_in(series_dir)
      
      series[series_name] = files if files.any?
    end
    
    series
  end

    private

    def find_videos_in(directory)
      Dir.glob(File.join(directory, '**', '*'))
         .select { |f| File.file?(f) && video_file?(f) }
    end

    def video_file?(path)
      VIDEO_EXTENSIONS.include?(File.extname(path).downcase)
    end
  end
end
