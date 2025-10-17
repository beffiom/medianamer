# frozen_string_literal: true

require 'net/http'
require 'json'

module MediaNamer
  module Api
    # TMDB API client
    class Tmdb
      BASE_URL = 'https://api.themoviedb.org/3'

      def initialize(api_key = ENV['TMDB_API_KEY'])
        @api_key = api_key
      end

      def search_show(name)
        response = get('/search/tv', query: name)
        response['results'] || []
      end

      def get_season(show_id, season_number)
        get("/tv/#{show_id}/season/#{season_number}")
      end

      def get_episodes(show_id, season_number)
        response = get_season(show_id, season_number)
        response['episodes'] || []
      end

      private

      def get(endpoint, query: nil)
        uri = URI("#{BASE_URL}#{endpoint}")
        params = { api_key: @api_key }
        params[:query] = query if query
        uri.query = URI.encode_www_form(params)
        # puts "DEBUG: Request = #{uri.inspect}, #{params.inspect}, #{uri.query.inspect}"  # Add this

        # Ruby might not be able to verify SSL certificates so we'll ignore it
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        response = http.get(uri.request_uri)
        JSON.parse(response.body)
      end
    end
  end
end
