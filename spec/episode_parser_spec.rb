# frozen_string_literal: true

require_relative '../lib/media_namer'

RSpec.describe MediaNamer::EpisodeParser do
  let(:parser) { described_class.new }

  describe '#parse' do
    context 'with files in Season folders' do
      let(:files) do
        [
          '/shows/Breaking Bad/Season 1/S01E01.mkv',
          '/shows/Breaking Bad/Season 1/S01E02.mkv',
          '/shows/Breaking Bad/Season 2/S02E01.mkv'
        ]
      end

      it 'extracts season and episode numbers' do
        result = parser.parse(files)

        expect(result.length).to eq(3)
        expect(result[0][:season]).to eq(1)
        expect(result[0][:episode]).to eq(1)
        expect(result[2][:season]).to eq(2)
        expect(result[2][:episode]).to eq(1)
      end

      it 'includes file paths' do
        result = parser.parse(files)

        expect(result[0][:path]).to eq(files[0])
        expect(result[0][:original_name]).to eq('S01E01.mkv')
      end
    end

    context 'with Specials folder' do
      let(:files) do
        [
          '/shows/Show/Specials/S00E01.mkv'
        ]
      end

      it 'treats Specials as Season 0' do
        result = parser.parse(files)

        expect(result[0][:season]).to eq(0)
        expect(result[0][:episode]).to eq(1)
      end
    end

    context 'with non-season folders' do
      let(:files) do
        [
          '/shows/Show/Extras/bonus.mkv',
          '/shows/Show/Season 1/S01E01.mkv'
        ]
      end

      it 'skips files not in Season folders' do
        result = parser.parse(files)

        expect(result.length).to eq(1)
        expect(result[0][:season]).to eq(1)
      end
    end
  end
end
