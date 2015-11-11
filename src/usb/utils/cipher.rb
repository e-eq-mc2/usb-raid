class Usb::Utils::Cipher
  ALGORITHM     = 'AES-256-CBC'
  STRETCH_ITER  = 2 ** 10
  PASSWORD_COST = 10

  class << self
    def generate_salt
      SecureRandom.urlsafe_base64
    end

    def encrypt_password(password, cost:)
      Usb::Utils::Bmt.run("#{self}.#{__method__}") {
        Usb::Utils.log "PASSWORD COST #{cost}"
        BCrypt::Password.create(password, cost: cost)
      }
    end

    def valid_password?(password:, encrypted_password:)
      BCrypt::Password.new(encrypted_password) == password
    end
  end

  attr_reader :encrypted_password

  def initialize(password:, salt:, password_cost: PASSWORD_COST)
    @encrypted_password = self.class.encrypt_password(password, cost: password_cost)

    setup_key_iv(password: password, salt: salt)
    setup_engine
  end

  def encrypt(data, reset: true)
    setup_engine if reset
    @encrypter.update(data) << @encrypter.final
  end

  def decrypt(data, reset: true)
    setup_engine if reset
    @decrypter.update(data) << @decrypter.final
  end

  private
  def setup_engine
    @encrypter = create_engine(:encrypt)
    @decrypter = create_engine(:decrypt)
  end

  def setup_key_iv(password:, salt:)
    Usb::Utils::Bmt.run("#{self.class}##{__method__}") {
      cipher = OpenSSL::Cipher.new(ALGORITHM)

      @key, @iv = generate_key_iv(
        password: password,
        salt:     salt,
        key_len:  cipher.key_len,
        iv_len:   cipher.iv_len
      )
    }
  end

  def create_engine(mode)
    cipher = OpenSSL::Cipher.new(ALGORITHM).send(mode)

    cipher.key = @key
    cipher.iv  = @iv

    cipher
  end

  def generate_key_iv(password:, salt:, key_len:, iv_len:)
    key_iv = OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, salt, STRETCH_ITER, key_len + iv_len)
    key    = key_iv[0      , key_len]
    iv     = key_iv[key_len, iv_len ]
    [key, iv]
  end
end
