# medianamer
Ruby CLI Application to automate the process of updating filename and metadata for local shows and movies for easy parsing with self hosted media applications like Jellyfin and Plex

Updated port of wikinamer: https://github.com/beffiom/wikinamer


## Features

- **Intelligent File Scanning** - Automatically detects single show or multi-show directory structures
- **TMDB Integration** - Fetches accurate episode titles and metadata from The Movie Database API
- **Batch Processing** - Queue multiple shows and seasons before applying changes
- **Safe Renaming** - Dry-run mode and user confirmation before modifying files
- **Metadata Updates** - Updates video file metadata using ffmpeg for proper display in media players
- **Standardized Naming** - Converts filenames to Plex/Jellyfin format: `S01E01 Episode Title.mkv`

## Examples
### Before

### Run

### After

## Installation
### Dependencies
- ffmpeg

```bash
1. git clone https://github.com/beffiom/medianamer.git
2. cd medianamer
3. bundle install
4. Add your TMDB API key to ~/.config/medianamer/.env as TMDB_API_KEY=your_key_here (https://developer.themoviedb.org/docs/getting-started)
5. gem build medianamer.gemspec
6. gem install medianamer-0.1.0.gem
```

## Configuration

Create a `.env` file in at ~/.config/medianamer/.env
```bash
TMDB_API_KEY=your_api_key_here
```

Get your TMDB API key at [themoviedb.org](https://www.themoviedb.org/settings/api)

## Usage

### Basic Usage
```bash
medianamer /path/to/tv/shows
```

### Dry Run Mode
```bash
medianamer --dry-run /path/to/tv/shows
```

### Expected Directory Structure
```
TV Shows/
├── Breaking Bad (2008)/
│   ├── Season 1/
│   │   ├── episode1.mkv
│   │   └── episode2.mkv
│   └── Season 2/
│       └── episode1.mkv
```

### Example Output
```
Processing: Breaking Bad (2008)

Select the correct show:
  1. Breaking Bad (2015)
  0. Skip this show

Enter selection: 1

Season 1:
  E01: Pilot
    File Before: episode1.mkv
    File After: S01E01 Pilot.mkv

Queue above changes? [y]es/[n]o: y

Apply all changes? [y]es/[n]o: y

Complete! Updated 62 files
```

## Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/episode_parser_spec.rb
```

## Technologies Used

- **Ruby 3.4** - Modern Ruby with latest performance improvements
- **RSpec** - Behavior-driven testing framework
- **dotenv** - Environment variable management
- **Net::HTTP** - Native HTTP client for API requests
- **ffmpeg** - Video metadata manipulation
