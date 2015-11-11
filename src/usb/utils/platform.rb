module Usb::Utils::Platform
  class << self
    def windows?
      !!File::ALT_SEPARATOR
    end

    def jruby?
      RUBY_ENGINE == 'jruby'
    end

    def hostname
      SysInfo.new.hostname
    end

    def username
      SysInfo.new.user
    end

    def os
      if OS.windows?
        "windows (#{Sys::Uname.sysname})"
      elsif OS.mac?
        "mac (#{Sys::Uname.sysname})"
      else
        "unix"
      end
    end
  end
end
