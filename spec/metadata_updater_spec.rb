# frozen_string_literal: true

require_relative '../lib/media_namer'
require 'fileutils'
require 'tmpdir'

RSpec.describe MediaNamer::MetadataUpdater do
  let(:updater) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:test_file) { "#{temp_dir}/test_video.mkv" }

  after { FileUtils.rm_rf(temp_dir) }

  before { FileUtils.touch(test_file) }

  describe '#update' do
    context 'when ffmpeg is not installed' do
      before do
        allow(updater).to receive(:ffmpeg_installed?).and_return(false)
      end

      it 'skips metadata update' do
        expect(updater).not_to receive(:update_metadata)
        updater.update(test_file, 'New Title', dry_run: false)
      end
    end

    context 'with dry run' do
      it 'does not modify the file' do
        allow(updater).to receive(:ffmpeg_installed?).and_return(true)
        updater.update(test_file, 'New Title', dry_run: true)
        expect(File.exist?(test_file)).to be true
      end
    end

    context 'when ffmpeg succeeds' do
      before do
        allow(updater).to receive(:ffmpeg_installed?).and_return(true)
        allow(updater).to receive(:system).and_return(true)
        allow(FileUtils).to receive(:mv) # Add this
      end

      it 'calls ffmpeg with correct parameters' do
        expect(updater).to receive(:system) do |*args|
          expect(args).to include('ffmpeg')
          expect(args).to include('-metadata')
          expect(args).to include('title=Episode Title')
          true
        end

        updater.update(test_file, 'Episode Title', dry_run: false)
      end
    end

    context 'when ffmpeg fails' do
      before do
        allow(updater).to receive(:ffmpeg_installed?).and_return(true)
        allow(updater).to receive(:system).and_return(false)
      end

      it 'does not crash' do
        expect do
          updater.update(test_file, 'Title', dry_run: false)
        end.not_to raise_error
      end

      it 'cleans up temp file' do
        allow(File).to receive(:exist?).and_return(true)
        expect(File).to receive(:delete).with(/tmp/)

        updater.update(test_file, 'Title', dry_run: false)
      end
    end
  end
end
