# frozen_string_literal: true

require_relative '../lib/media_namer'

RSpec.describe MediaNamer::Api::Tmdb do
  let(:client) { described_class.new('fake_api_key') }

  describe '#search_show' do
    it 'returns search results' do
      allow(client).to receive(:get).and_return({
                                                  'results' => [
                                                    { 'name' => 'Breaking Bad', 'id' => 1396,
                                                      'first_air_date' => '2008-01-20' }
                                                  ]
                                                })

      results = client.search_show('Breaking Bad')

      expect(results.length).to eq(1)
      expect(results[0]['name']).to eq('Breaking Bad')
    end

    it 'returns empty array when no results' do
      allow(client).to receive(:get).and_return({ 'results' => [] })

      results = client.search_show('NonexistentShow')

      expect(results).to eq([])
    end
  end

  describe '#get_episodes' do
    it 'returns episode list' do
      allow(client).to receive(:get_season).and_return({
                                                         'episodes' => [
                                                           { 'name' => 'Pilot', 'episode_number' => 1 },
                                                           { 'name' => 'Cat in the Bag', 'episode_number' => 2 }
                                                         ]
                                                       })

      episodes = client.get_episodes(1396, 1)

      expect(episodes.length).to eq(2)
      expect(episodes[0]['name']).to eq('Pilot')
    end
  end
end
