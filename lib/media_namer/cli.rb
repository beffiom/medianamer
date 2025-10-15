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
      tmdb = MediaNamer::Api::Tmdb.new
      renamer = MediaNamer::FileRenamer.new
      metadata_updater = MediaNamer::MetadataUpdater.new
      
      series = scanner.scan(directory)
      
      series.each do |show_name, files|
        puts "#{show_name}:"
        episodes = parser.parse(files)
        
        episodes.first(2).each do |ep|
          puts "  S#{ep[:season].to_s.rjust(2, '0')}E#{ep[:episode].to_s.rjust(2, '0')} - #{ep[:original_name]}"
        end
        puts "  ... (#{episodes.count} total)\n\n"
      end

      series.each do |show_name, files|
        puts "Processing: #{show_name}"
        
        # Remove year from show name for API search
        clean_name = show_name.gsub(/\s*\(\d{4}\)\s*/, '').strip
        
        results = tmdb.search_show(clean_name)
        
        if results.empty?
          puts "  ⚠ No results found\n\n"
          puts "Try manual search? ([y]es/[n]o)"
          user_input = $stdin.gets.chomp
          if user_input == 'y' || user_input == 'yes'
            puts "Type name of show:"
            show_name = $stdin.gets.chomp
            results = tmdb.search_show(show_name)
          else
            next
          end
        end
        
        show = results.first
        show_id = show['id']
        puts "  Found: #{show['name']} (#{show['first_air_date']&.split('-')&.first})"
        episodes = parser.parse(files)
        puts "  #{episodes.count} episodes across #{episodes.map { |e| e[:season] }.uniq.count} seasons\n\n"

        correct_show = 'no'
        until correct_show == 'yes' || correct_show == 'y'
          puts "\nIs this correct? ([y]es/[n]o)"
          correct_show = $stdin.gets.chomp
          if correct_show == 'n' || correct_show == 'no'
            puts "\nType name of show:"
            show_name = $stdin.gets.chomp
            results = tmdb.search_show(show_name)
          else
            next
          end
          
          show = results.first
          show_id = show['id']
          puts "\n  Found: #{show['name']} (#{show['first_air_date']&.split('-')&.first})"
          puts "  #{episodes.count} episodes across #{episodes.map { |e| e[:season] }.uniq.count} seasons\n\n"
        end

        episodes = parser.parse(files)
        seasons = episodes.group_by { |ep| ep[:season] }
        
        seasons.each do |season_num, season_episodes|
          puts "\n  Season #{season_num}:"
          api_episodes = tmdb.get_episodes(show_id, season_num)

          
          season_episodes.each do |ep|
            api_ep = api_episodes[ep[:episode] - 1]
            episode_title = api_ep ? api_ep['name'] : 'Unknown'
            
            puts "    E#{ep[:episode].to_s.rjust(2, '0')}: #{episode_title}"
            puts "      File: #{ep[:original_name]}"
          end

          if api_episodes.length != season_episodes.length
              puts "    ⚠ Warning: Found #{season_episodes.length} files but API reports #{api_episodes.length} episodes"
          end


          puts "\nUpdate all files? ([yes]/[no])"
          update_files = $stdin.gets.chomp
          if update_files == 'y' || update_files == 'yes'
            season_episodes.each do |ep|
              api_ep = api_episodes[ep[:episode] - 1]
              episode_title = api_ep ? api_ep['name'] : 'Unknown'
              
              puts "    E#{ep[:episode].to_s.rjust(2, '0')}: #{episode_title}"
              
              new_path = renamer.rename(ep, episode_title, dry_run: options[:dry_run])
              metadata_updater.update(new_path, episode_title, dry_run: options[:dry_run])
            end
          else
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
