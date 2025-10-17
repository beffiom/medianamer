# frozen_string_literal: true

require_relative '../lib/media_namer'
require 'fileutils'
require 'tmpdir'

RSpec.describe MediaNamer::FileRenamer do
  let(:renamer) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe '#rename' do
    let(:original_file) { "#{temp_dir}/old_name.mkv" }
    let(:episode) do
      {
        path: original_file,
        season: 1,
        episode: 5,
        original_name: 'old_name.mkv'
      }
    end

    before { FileUtils.touch(original_file) }

    context 'with dry run' do
      it 'does not rename the file' do
        renamer.rename(episode, 'New Title', dry_run: true)

        expect(File.exist?(original_file)).to be true
        expect(File.exist?("#{temp_dir}/S01E05 New Title.mkv")).to be false
      end
    end

    context 'without dry run' do
      it 'renames the file' do
        new_path = renamer.rename(episode, 'New Title', dry_run: false)

        expect(File.exist?(original_file)).to be false
        expect(File.exist?(new_path)).to be true
        expect(new_path).to match(/S01E05 New Title\.mkv/)
      end
    end

    context 'when file already correctly named' do
      let(:correct_file) { "#{temp_dir}/S01E05 Correct Title.mkv" }
      let(:episode) do
        {
          path: correct_file,
          season: 1,
          episode: 5,
          original_name: 'S01E05 Correct Title.mkv'
        }
      end

      before { FileUtils.touch(correct_file) }

      it 'skips renaming' do
        result = renamer.rename(episode, 'Correct Title', dry_run: false)

        expect(result).to eq(correct_file)
      end
    end

    context 'with invalid characters in title' do
      it 'sanitizes the filename' do
        new_path = renamer.rename(episode, 'Title: With/Bad*Chars', dry_run: false)

        expect(File.basename(new_path)).to eq('S01E05 Title WithBadChars.mkv')
      end
    end
  end
end
