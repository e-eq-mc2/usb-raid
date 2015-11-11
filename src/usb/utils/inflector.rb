module Usb::Utils::Inflector
  def to_type_name(c)
    c.to_s.demodulize
  end

  def to_resource_name(c)
    to_type_name(c).underscore.pluralize
  end
end

module Usb::Utils
  extend Inflector
end
