module Usb::Utils::Parallel
  def self.map(ary, mode: :parallel, thread_count: 1)
    Usb::Utils.log "PROCESS mode: #{mode} task count: #{ary.count} thread_count: #{thread_count}".blue

    case mode
    when :parallel
      Parallel.map(ary, in_threads: thread_count, with_index: true) {|item,index| yield(item, index)}
    when :serial
      ary.map.with_index {|item,index| yield(item, index)}
    else fail
    end
  end
end
