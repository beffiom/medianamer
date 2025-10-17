# frozen_string_literal: true

require 'optparse'

module MediaNamer
  # CLI interface for MediaNamer
  class CLI
    def run(args)
      options = parse_options(args)
      directory = args.first || Dir.pwd

      logger = MediaNamer::AppLogger
      logger.info("MediaNamer v#{MediaNamer::VERSION}")
      logger.info("Scanning: #{directory}")
      logger.info("Options: #{options}")

      scanner = MediaNamer::FileScanner.new
      parser = MediaNamer::EpisodeParser.new
      tmdb = MediaNamer::Api::Tmdb.new
      renamer = MediaNamer::FileRenamer.new
      metadata_updater = MediaNamer::MetadataUpdater.new

      series = scanner.scan(directory)

      puts "\nSeries Discovered in Directory:"
      series.each do |show_name|
        puts "  #{show_name}"
      end

      queue = []

      series.each do |show_name, files|
        puts "\nProcessing: #{show_name}"

        clean_name = show_name.gsub(/\s*\(\d{4}\)\s*/, '').strip
        results = tmdb.search_show(clean_name)

        if results.empty?
          logger.error("⚠ No results found for #{show_name}")
          next
        end

        puts "\n  Select the correct show:"
        results.first(5).each_with_index do |result, index|
          year = result['first_air_date']&.split('-')&.first || 'N/A'
          puts "    #{index + 1}. #{result['name']} (#{year})"
        end
        puts '    0. Skip this show'

        print "\n  Enter selection: "
        selection = $stdin.gets.chomp.to_i

        next if selection.zero?

        show = results[selection - 1]
        show_id = show['id']
        puts "Selected: #{show['name']}"

        episodes = parser.parse(files)
        seasons = episodes.group_by { |ep| ep[:season] }

        seasons.each do |season_num, season_episodes|
          puts "\n  Season #{season_num}:"
          api_episodes = tmdb.get_episodes(show_id, season_num)

          season_episodes.each do |ep|
            api_ep = api_episodes[ep[:episode] - 1]
            episode_title = api_ep ? api_ep['name'] : 'Unknown'
            puts "    E#{ep[:episode].to_s.rjust(2, '0')}: #{episode_title}"
            puts "      File Before: #{ep[:original_name]}"
            puts "      File After: S#{ep[:season].to_s.rjust(2,
                                                              '0')}E#{ep[:episode].to_s.rjust(2,
                                                                                              '0')} #{episode_title}#{File.extname(ep[:path])}"
          end

          if api_episodes.length != season_episodes.length
            logger.error("    ⚠ Warning: Found #{season_episodes.length} files but API reports #{api_episodes.length} episodes")
          end

          print "\n  Queue above changes? [y]es/[n]o: "
          queue_changes = $stdin.gets.chomp.downcase

          if %w[y yes].include?(queue_changes)
            season_episodes.each do |ep|
              api_ep = api_episodes[ep[:episode] - 1]
              next unless api_ep

              queue << {
                episode: ep,
                title: api_ep['name'],
                show_name: show['name']
              }
            end
          else
            puts "  Skipped Season #{season_num}"
          end
        end
      end

      if queue.empty?
        puts "\nNo changes queued."
        return
      end

      puts "\n#{'=' * 50}"
      puts "QUEUED CHANGES (#{queue.count} files)"
      puts '=' * 50

      print "\nApply all changes? [y]es/[n]o: "
      apply_changes = $stdin.gets.chomp.downcase

      unless %w[y yes].include?(apply_changes)
        puts "\nNo changes not applied..."
        puts "\nExiting program."
        return
      end

      queue.each do |item|
        ep = item[:episode]
        title = item[:title]
        show_name = item[:show_name]
        puts "#{show_name} S#{ep[:season].to_s.rjust(2, '0')}E#{ep[:episode].to_s.rjust(2, '0')}: #{title}\n"

        new_path = renamer.rename(ep, title, dry_run: false)
        metadata_updater.update(new_path, title, dry_run: false)
      end

      puts "\nComplete! Updated #{queue.count} files"
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
