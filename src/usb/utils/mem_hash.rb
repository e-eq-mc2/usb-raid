class Usb::Utils::MemHash < Hash
  attr_reader :created_at

  def initialize
    super
    @created_at = Time.now
  end
end
