# frozen_string_literal: true

require 'optparse'

module MediaNamer
  # CLI interface for MediaNamer
  class CLI
    def run(args)
      options = parse_options(args)
      directory = args.first || Dir.pwd
      
      puts "MediaNamer v#{MediaNamer::VERSION}"
      puts "Scanning: #{directory}"
      puts "Dry run: #{options[:dry_run]}\n\n"

      scanner = MediaNamer::FileScanner.new
      parser = MediaNamer::EpisodeParser.new
      
      series = scanner.scan(directory)
      
      series.each do |show_name, files|
        puts "#{show_name}:"
        episodes = parser.parse(files)
        
        episodes.first(2).each do |ep|
          puts "  S#{ep[:season].to_s.rjust(2, '0')}E#{ep[:episode].to_s.rjust(2, '0')} - #{ep[:original_name]}"
        end
        puts "  ... (#{episodes.count} total)\n\n"
      end
    end

    private

    def parse_options(args)
      options = { dry_run: false }

      OptionParser.new do |opts|
        opts.banner = 'Usage: medianamer [options] [directory]'

        opts.on('-d', '--dry-run', 'Preview changes without renaming') do
          options[:dry_run] = true
        end

        opts.on('-h', '--help', 'Show this help') do
          puts opts
          exit
        end
      end.parse!(args)

      options
    end
  end
end
