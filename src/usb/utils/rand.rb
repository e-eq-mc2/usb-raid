require_relative 'base'

module Usb::Utils::Rand
  class << self
    def rand_within(minval, maxval)
      dv  = maxval - minval
      minval + dv * rand()
    end

    def sleep_randomly(minsec: 0.1, maxsec: 1.0)
      sec = rand_within(minsec, maxsec)
      sleep(sec)

      sec
    end
  end
end
