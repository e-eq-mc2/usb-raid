def use_ansicolor?
  false
end

if use_ansicolor?
  require 'term/ansicolor'

  class String
    include Term::ANSIColor
  end
else
  require 'awesome_print'
end

class String
  def to_nfc
    fail if encoding != Encoding::UTF_8
    super
  end

  def to_codepoints
    codepoints.map {|cp| sprintf("U+%04X", cp)}
  end

  def utf8?
    # Note: This method doesn't check bitecode
    if encoding != Encoding::UTF_8
      return false 
    end

    #if unicode_normalized?
    #  Usb::Utils.error_message("unicode normalization is not nfc <#{self}>")
    #  return false
    #end

    true
  end

  def ^ (second)
    s = ""
    s.force_encoding("ASCII-8BIT")
    [self.size,second.size].max.times do |i|
      s << ((self[i] || 0).ord ^ (second[i] || 0).ord)
    end
    return s
  end

  def xor(second)
    s = ""
    s.force_encoding("ASCII-8BIT")
    [self.size,second.size].max.times.zip(self.each_byte.to_a,second.each_byte.to_a) do |i,a,b|
      s << a ^ b
    end
  end

end
