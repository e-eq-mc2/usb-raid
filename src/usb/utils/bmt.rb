module Usb::Utils::Bmt
  class << self
    TIME_MIN = 1.0 * 10 ** -6

    def enable_log
      @silence = false
    end

    def disable_log
      @silence = true
    end

    def silence
      @silence = defined?(@silence) ? @silence : false
    end

    def run(tag = '', size: 0)
      result = nil
      time = Benchmark.realtime {result = yield}
      push(tag, time, size)

      return result if silence

      tm = "%.3f" % time
      sz = to_size(size).human_size
      sp = speed(size, time).human_size
      Usb::Utils.log "#{tag}: #{tm} sec, #{sz}, #{sp} /sec"
      result
    end

    def summary
      Usb::Utils.log "** BMT SUMMARY **"
      @total.keys.each do |tag|
        tt = "%.3f" % total_time(tag)
        tc = total_count(tag).to_s
        ts = total_size(tag).human_size
        at = "%.3f" % ave_time(tag)
        as = ave_speed(tag).human_size

        Usb::Utils.log "  #{tag}: total #{tt} sec, #{tc} call, #{ts}; average #{at} sec/call, #{as} /sec/call"
      end
      Usb::Utils.log "** *********** **"
    end

    def to_size(size)
      ( size.is_a? Proc ) ? size.call : size
    end

    def speed(size, time)
      time > 0 ? to_size(size) / time : TIME_MIN
    end

    def total
      @total ||= ::Hash.new{|h,k| h[k] = {time: 0, count: 0, size: 0}}
    end

    def total_time(key)
      self.total[key][:time ]
    end

    def total_count(key)
      self.total[key][:count]
    end

    def total_size(key)
      self.total[key][:size]
    end

    def push(key, dt, size = 0)
      self.total[key][:time ] += dt
      self.total[key][:size ] += to_size(size)
      self.total[key][:count] += 1
    end

    def ave_time(key)
      t = total_time(key)
      c = total_count(key)
      c > 0 ? t / c : 0.0
    end

    def ave_speed(key)
      speed(total_size(key), total_time(key))
    end
  end
end
