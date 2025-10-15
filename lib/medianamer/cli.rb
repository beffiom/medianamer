# frozen_string_literal: true

require 'optparse'

module MediaNamer
  # CLI interface for MediaNamer
  class CLI
    def run(args)
      options = parse_options(args)
      directory = args.first || Dir.pwd

      puts "Medianamer v#{VERSION}"
      puts "Scanning: #{directory}"
      puts "Dry run: #{options[:dry_run]}"
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
