##############################
### Extend gem 'Clockwork' ###
##############################
module Clockwork
  class Event
    def reset_period(period)
      @period = period
    end

    def reset_at(at)
      @at = Clockwork::At.parse(at)
    end

    def reset_last(last)
      self.last = convert_timezone(last)
    end

    org_run_now = instance_method(:run_now?)
    define_method(:run_now?) do |t|
      org_run_now.bind(self).(t)
    end

    org_execute = instance_method(:execute)
    define_method(:execute) do
      org_execute.bind(self).()
    end
  end

  class Manager
    attr_reader :events
  end
end
##############################

module Usb::Utils::Timer
  PERIOD = 12.hours

  class << self
    attr_accessor :logger

    def logger
      @logger ||= Usb::Utils.logger
    end

    def clear!
      Clockwork.clear!
    end

    def event
      Clockwork.manager.events.first
    end

    def every(period, job, options = {}, &block)
      fail "event(#{event.job}) is already set (#{job} can't be set)" if event
      logger.info "Set the timer at #{options[:at]}"

      @period = options[:period]
      @at     = options[:at    ]
      @logger = options[:logger]

      Clockwork.manager.every(period, job, options, &block)
    end

    def handler(&block)
      Clockwork.manager.handler(&block)
    end

    def reset_period(period)
      logger.info "Reset the timer period #{@period} -> #{period}"

      @period = period
      _event = event
      _event.reset_period(period) if _event.present?
    end

    def reset_at(at)
      logger.info "Reset the timer at #{@at} -> #{at}"

      @at = at
      _event = event
      _event.reset_at(at) if _event.present?
    end

    def reset_last(last = Time.now)
      logger.info "Reset the timer last #{@last} -> #{last}"

      @last = last
      _event = event
      _event.reset_last(last) if _event.present?
    end

    def run
      Clockwork.manager.error_handler do |e|
        logger.log_exception e
        raise e
      end

      # Start infinite loop
      Clockwork.manager.run
    end

    def random_at
      "#{random_HH}:#{random_M0}"
    end

    def random_HH(from: 8, to: 20)
      fail Usb::Utils.error_message("form #{form}") if from < 0 || from > 23
      fail Usb::Utils.error_message("to #{to}")     if to   < 0 || to   > 23

      fail Usb::Utils.error_message("#{to} < #{from}") if to < from

      h = [*(from..to)].sample(1).first
      hh = "%02d" % h
    end

    def random_MM(from = 0, to = 59)
      fail Usb::Utils.error_message("form #{form}") if from < 0 || from > 59
      fail Usb::Utils.error_message("to #{to}")     if to   < 0 || to   > 59

      fail Usb::Utils.error_message("#{to} < #{from}") if to < from

      m = [*(from..to)].sample(1).first
      mm = "%02d" % m
    end

    def random_M0(from = 0, to = 5)
      fail Usb::Utils.error_message("form #{form}") if from < 0 || from > 5
      fail Usb::Utils.error_message("to #{to}")     if to   < 0 || to   > 5

      fail Usb::Utils.error_message("#{to} < #{from}") if to < from

      m = [*(from..to)].sample(1).first * 10
      mm = "%02d" % m
    end
  end
end
