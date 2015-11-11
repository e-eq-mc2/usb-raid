module Usb::Utils::Time
  class << self
    def load(str)
      ::Time.parse str
    end

    def dump(time)
      time.to_datetime.rfc3339
    end

    def format(str)
      time = load(str)
      dump(time)
    end

    def simple_now
      DateTime.now.strftime("%Y%m%d%H%M%S")
    end
  end
end
