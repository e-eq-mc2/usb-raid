module Usb::Utils::Logger
  require 'logger'


  attr_accessor :logger

  SHIFT_AGE  = 3
  SHIFT_SIZE = 8 * 2 ** 20

  def backtrace
    begin
      fail
    rescue => e
      e.backtrace
    end
  end

  def logger_path=(path)
    @logger = ::Logger.new(path, SHIFT_AGE, SHIFT_SIZE)
  end

  def logger
    @logger ||= ::Logger.new(STDOUT, SHIFT_AGE, SHIFT_SIZE)
  end

  def log(msg, level: :info)
    logger.send(level, msg)
  end

  def log_error(msg)
    logger.error error_message(msg)
  end

  def log_warn(msg)
    logger.warn warn_message(msg)
  end

  def log_exception(e)
    logger.error "#{e.message} (#{e.class})".red
    logger.error e.backtrace.join("\n")
  end

  def calling_location
    caller[1]
  end

  def caller_location
    caller[2]
  end

  def pretty_calling_location
    to_pretty_caller(calling_location)
  end

  def pretty_caller_location
    to_pretty_caller(caller_location)
  end

  def to_pretty_caller(c)
    md = c.match(/`(.*)'/)
    md[1].sub('block in ', '')
  end

  def error_message(msg)
    "ERROR: #{msg}".red
  end

  def warn_message(msg)
    "WARN: #{msg}".red
  end
end

module Usb::Utils
  extend Logger
end
