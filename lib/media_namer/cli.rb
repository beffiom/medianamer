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
      logger.info("Dry run: #{options[:dry_run]}\n\n")
      
      scanner = MediaNamer::FileScanner.new
      parser = MediaNamer::EpisodeParser.new
      tmdb = MediaNamer::Api::Tmdb.new
      renamer = MediaNamer::FileRenamer.new
      metadata_updater = MediaNamer::MetadataUpdater.new
      
      series = scanner.scan(directory)

      queue = []
      
      series.each do |show_name, files|
        puts "#{show_name}:"
      #  episodes = parser.parse(files)
      #  
      #  episodes.first(2).each do |ep|
      #    puts "  S#{ep[:season].to_s.rjust(2, '0')}E#{ep[:episode].to_s.rjust(2, '0')} - #{ep[:original_name]}"
      #  end
        puts "  ... (#{episodes.count} total)\n\n"
      end

      series.each do |show_name, files|
        puts "\nProcessing: #{show_name}"
        
        clean_name = show_name.gsub(/\s*\(\d{4}\)\s*/, '').strip
        results = tmdb.search_show(clean_name)
        
        if results.empty?
          logger.error("⚠ No results found for #{show_name}")
          print "Try manual search? [y]es/[n]o: "
          user_input = $stdin.gets.chomp
          if user_input == 'y' || user_input == 'yes'
            print "Type name of show: "
            show_name = $stdin.gets.chomp
            results = tmdb.search_show(show_name)
          else
            next
          end
        end

        puts "\n  Select the correct show:"
        results.first(5).each_with_index do |result, index|
          year = result['first_air_date']&.split('-')&.first || 'N/A'
          puts "    #{index + 1}. #{result['name']} (#{year})"
        end
        puts "    0. None of these"
        
        print "\n  Enter selection (1-#{[results.length, 5].min}): "
        selection = $stdin.gets.chomp.to_i
        
        if selection.zero? || selection > results.length
          print "\n  Type name of show: "
          show_name = $stdin.gets.chomp
          results = tmdb.search_show(show_name)
          print "\n  Select the correct show: "
          results.first(5).each_with_index do |result, index|
            year = result['first_air_date']&.split('-')&.first || 'N/A'
            puts "    #{index + 1}. #{result['name']} (#{year})"
          end
          puts "    0. Skip this show"
          
          print "\n  Enter selection (1-#{[results.length, 5].min}): "
          selection = gets.chomp.to_i
          if selection.zero? || selection > results.length
            puts "  Skipped\n\n"
            next
          end
        end
        
        show = results[selection-1]
        show_id = show['id']
        puts "\n  Selected: #{show['name']} (#{show['first_air_date']&.split('-')&.first})"
        episodes = parser.parse(files)
        puts "    #{episodes.count} episodes across #{episodes.map { |e| e[:season] }.uniq.count} seasons\n\n"

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
            puts "      File After: S#{ep[:season].to_s.rjust(2, '0')}E#{ep[:episode].to_s.rjust(2, '0')} #{episode_title}#{File.extname(ep[:path])}"
          end

          if api_episodes.length != season_episodes.length
            logger.error("    ⚠ Warning: Found #{season_episodes.length} files but API reports #{api_episodes.length} episodes")
          end


          print "\n  Update all files? [y]es/[n]o: "
          update_files = $stdin.gets.chomp
          if update_files == 'y' || update_files == 'yes'
            season_episodes.each do |ep|
              api_ep = api_episodes[ep[:episode] - 1]
              episode_title = api_ep ? api_ep['name'] : 'Unknown'
              
              puts "    E#{ep[:episode].to_s.rjust(2, '0')}: #{episode_title}"
              
              new_path = renamer.rename(ep, episode_title, dry_run: options[:dry_run])
              if File.exist?(new_path)
                metadata_updater.update(new_path, episode_title, dry_run: false)
              end
            end
          else
            puts "  Skipped Season #{season_num}..."
            next
          end
        end
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
