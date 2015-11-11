module Usb::Utils::Digest
  class << self 
    def hex(data)
      sha256(data)
    end

    def md5(data)
      ::Digest::MD5.hexdigest data
    end

    def sha1(data)
      ::Digest::SHA1.hexdigest data
    end

    def sha256(data)
      ::Digest::SHA256.hexdigest data
    end
  end
end
