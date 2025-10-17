# frozen_string_literal: true

require_relative '../lib/media_namer'
require 'fileutils'
require 'tempfile'

RSpec.describe MediaNamer::FileScanner do
  let(:scanner) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe '#scan' do
    context 'with single show directory' do
      before do
        FileUtils.mkdir_p("#{temp_dir}/Season 1")
        FileUtils.touch("#{temp_dir}/Season 1/episode1.mkv")
        FileUtils.touch("#{temp_dir}/Season 1/episode2.mp4")
      end

      it 'detects single show structure' do
        result = scanner.scan(temp_dir)

        expect(result.keys.length).to eq(1)
        expect(result[File.basename(temp_dir)]).to include(
          match(/episode1\.mkv/),
          match(/episode2\.mp4/)
        )
      end
    end

    context 'with multiple shows directory' do
      before do
        FileUtils.mkdir_p("#{temp_dir}/Show A/Season 1")
        FileUtils.mkdir_p("#{temp_dir}/Show B/Season 1")
        FileUtils.touch("#{temp_dir}/Show A/Season 1/ep1.mkv")
        FileUtils.touch("#{temp_dir}/Show B/Season 1/ep1.mkv")
      end

      it 'finds all shows' do
        result = scanner.scan(temp_dir)

        expect(result.keys.length).to eq(2)
        expect(result.keys).to include('Show A', 'Show B')
      end
    end

    context 'with non-video files' do
      before do
        FileUtils.mkdir_p("#{temp_dir}/Season 1")
        FileUtils.touch("#{temp_dir}/Season 1/video.mkv")
        FileUtils.touch("#{temp_dir}/Season 1/subtitle.srt")
      end

      it 'only includes video files' do
        result = scanner.scan(temp_dir)

        files = result.values.first
        expect(files.length).to eq(1)
        expect(files.first).to match(/video\.mkv/)
      end
    end
  end
end
