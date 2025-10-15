# frozen_string_literal: true

require 'logger'

module MediaNamer
  # Logging wrapper
  class AppLogger
    def self.instance
      @logger ||= Logger.new($stdout).tap do |log|
        log.level = Logger::INFO
        log.formatter = proc do |severity, datetime, _progname, msg|
          "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n"
        end
      end
    end

    def self.info(msg)
      instance.info(msg)
    end

    def self.error(msg)
      instance.error(msg)
    end

    def self.debug(msg)
      instance.debug(msg)
    end
  end
end
