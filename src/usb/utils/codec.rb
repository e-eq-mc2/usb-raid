class Usb::Utils::Codec
  class BadPassword < StandardError; end

  class << self
    def enable_log
      @silence = false
    end

    def disable_log
      @silence = true
    end

    def silence
      @silence = defined?(@silence) ? @silence : false
    end
  end

  def initialize(params)
    @cipher = Usb::Utils::Cipher.new(params)
  end

  def encode(data)
    size0 = data.bytesize

    compressed_data = compress(data)
    size1 = compressed_data.bytesize

    encrypted_data  = encrypt(compressed_data)
    size2 = encrypted_data.bytesize

    log_size_change(size0, size1, size2) if not self.class.silence
    encrypted_data
  end

  def decode(data)
    encrypted_data  = data
    compressed_data = decrypt(encrypted_data)
    decompress(compressed_data)
  end

  def encrypted_password
    @cipher.encrypted_password
  end

  private
  def compress(data)
    #Usb::Utils::Bmt.run("#{__method__}", size: data.bytesize) {
      Zlib::Deflate.deflate(data)
    #}
  end

  def decompress(data)
    #Usb::Utils::Bmt.run("#{__method__}", size: data.bytesize) {
      Zlib::Inflate.inflate(data)
    #}
  end

  def encrypt(data)
    #Usb::Utils::Bmt.run("#{__method__}", size: data.bytesize) {
      @cipher.encrypt(data)
    #}
  end

  def decrypt(data)
    #Usb::Utils::Bmt.run("#{__method__}", size: data.bytesize) {
      @cipher.decrypt(data)
    #}
  end

  def log_size_change(size0, size1, size2)
    msg0 = "#{size0.human_size}"
    msg1 = "#{size1.human_size} (%.2f %%)" % to_percentage(size1, size0) 
    msg2 = "#{size2.human_size} (%.2f %%)" % to_percentage(size2, size0)
    Usb::Utils.log "#{self.class}#encode: #{msg0} -COMPRESS-> #{msg1} -ENCRYPT-> #{msg2}", level: :debug
  end

  def to_percentage(a,b)
    (a.to_f / b) * 100.0
  end
end
