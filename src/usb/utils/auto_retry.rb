module Usb::Utils::AutoRetry
  RETRY_LIMIT          = 4
  BASE_INTERVAL        = 1.0 # Note: in sec
  EXCEPTIONS_TO_RESCUE = [StandardError]

  class << self
    def run(
      retry_limit:   RETRY_LIMIT, 
      base_interval: BASE_INTERVAL, 
      max_interval:  nil, 
      before_retry:  nil, 
      exceptions_to_rescue: EXCEPTIONS_TO_RESCUE
    )
      fail if retry_limit < 0
      max_interval ||= base_interval * 2 ** retry_limit

      started_at  = Time.now
      

      retry_count = 0
      begin
        return yield retry_count
      rescue *exceptions_to_rescue => e
        raise e if retry_count >= retry_limit
        retry_count += 1

        ave_interval = base_interval * 2 ** (retry_count - 1)
        rnd_interval = Usb::Utils::Rand.rand_within(ave_interval * 0.75, ave_interval * 1.25)
        interval     = clamp(rnd_interval, base_interval, max_interval)

        tinfo = time_info(started_at, interval, ave_interval)
        einfo = exception_info(e)
        Usb::Utils.log "RETRIING #{retry_count}/#{retry_limit} #{tinfo} (#{einfo})".red

        before_retry.call(e, retry_count, Time.now - started_at) if before_retry

        sleep interval
        retry
      end
    end

    def run_with_wndctrl(tasks, params = {})
      slice_count = [tasks.count, 1].max

      run(params) do |retry_count|
        if retry_count > 0
          # Note: Each request size reduces while retrying like TCP congestion-avoidance algorithm
          # e.g. request size: 15 -> 8 -> 4 -> 2 -> 1 -> 1 ....
          slice_count = (slice_count / 2.0).ceil

          Usb::Utils.log "REDUCED COUNT TO #{slice_count} (ORIGINAL: #{tasks.count})".red
        end

        result = []
        tasks.each_slice(slice_count) do |slice|
          res = yield slice, retry_count
          result += res
        end

        result
      end
    end

    def clamp(val, minval, maxval)
      [minval, [val, maxval].min].max
    end

    def time_info(started_at, interval, ave_interval)
      elapsed_time = Time.now - started_at
      "IN #{format_sec(interval)} (#{format_sec(ave_interval)}) sec, elapsed: #{format_sec(elapsed_time)} sec"
    end

    def exception_info(e)
      "EXCEPTION #{e.message} #{e.class} @ #{e.backtrace.first}"
    end

    def format_sec(val)
      "%.4f" % [val]
    end

  end
end
