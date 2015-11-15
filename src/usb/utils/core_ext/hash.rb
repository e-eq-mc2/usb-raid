class Hash
  require 'active_support'
  require 'active_support/core_ext'
  require 'active_support/core_ext/hash'

  def valid_types?(key2type)
    key2type.each do |k,expected_type|
      v = self[k]

      types = 
        if expected_type.is_a?(Array) && !expected_type.empty? 
          expected_type 
        else
          [expected_type]
        end

      if types.none? {|t| t.nil? ? v.nil? : v.is_a?(t) }
        Usb::Utils.logger.info "The value: #{v} of key: #{k} is not a #{types}, it's #{v.class}".red
        return false
      end
    end

    return true
  end

  def safe_fetch(key, defval)
    raise KeyError.new("key not found: \"#{key}\"") if not key?(key) 
    self[key] || defval
  end

  #def sweep(keys)
  #  keys.each do |k| 
  #    fail Usb::Utils.error_message("NOT FOUND KEY #{k}") if not key?(k)
  #    delete(k)
  #  end
  #end
end
