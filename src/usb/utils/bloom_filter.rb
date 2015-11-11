class Usb::Utils::BloomFilter

  class << self
    def load(params)
      bf = new
      bf.load(params)
      bf
    end

    def compute_checksum(bitmap)
      checksum = ''
      bitmap.each do |v| 
        checksum = Usb::Utils::Digest.sha1(checksum + v.to_s)
      end
      checksum
    end
  end

  attr_reader :size, :hashes, :bitmap

  def initialize(size: 0, hashes: 0, bitmap: nil)
    setup(size: size, hashes: hashes, bitmap: bitmap)
  end

  def setup(size:, hashes:, bitmap:)
    @size     = size
    @hashes   = hashes
    @bitarray = BitArray.new(size, bitmap) 
  end

  def bitmap
    @bitarray.field
  end

  def index(key, iv)
    index1(key, iv)
  end

  def <<(key)
    hashes.times do |hi|
      idx = index(key, hi)
      @bitarray[idx] = 1
    end

    nil
  end

  def include?(key)
    hashes.times.all? do |hi| 
      idx  = index(key, hi)
      @bitarray[idx] == 1
    end
  end

  def load(params)
    size   = params.fetch(:size    ) || fail
    hashes = params.fetch(:hashes  ) || fail
    bitmap = params.fetch(:bitmap  ) || fail

    setup(size: size, hashes: hashes, bitmap: bitmap)

    self
  end

  def checksum
    self.class.compute_checksum(bitmap)
  end

  def dump
    {
      size:     size  ,
      hashes:   hashes,
      bitmap:   bitmap,
      checksum: checksum
    }
  end

  def setup_test
    TEST_DATA.each {|d| self.<< d}
  end

  def reliable?
    TEST_DATA.all? do |d| 
      found = include? d
      Usb::Utils.log_error "#{self.class}##{__method__} '#{d}' is not included" if not found
      found
    end
  end

  private
  def index0(key, iv)
    crc = Zlib.crc32(key, iv) 
    idx = crc % @size
    idx
  end

  def index1(key, iv)
    crc = Zlib.crc32("#{key}:#{iv}") 
    idx = crc % @size
    idx
  end

  def index2(key, iv)
    digest = Usb::Utils::Digest.md5("#{key}:#{iv}")
    crc = Zlib.crc32(digest)
    idx = crc % @size
    idx
  end

  #Note: DO NOT TOUCH !!!!
  TEST_DATA = [ #Note: SHA1 of 'a' to 'z'
    '86f7e437faa5a7fce15d1ddcb9eaeaea377667b8',
    'e9d71f5ee7c92d6dc9e92ffdad17b8bd49418f98',
    '84a516841ba77a5b4648de2cd0dfcb30ea46dbb4',
    '3c363836cf4e16666669a25da280a1865c2d2874',
    '58e6b3a414a1e090dfc6029add0f3555ccba127f',
    '4a0a19218e082a343a1b17e5333409af9d98f0f5',
    '54fd1711209fb1c0781092374132c66e79e2241b',
    '27d5482eebd075de44389774fce28c69f45c8a75',
    '042dc4512fa3d391c5170cf3aa61e6a638f84342',
    '5c2dd944dde9e08881bef0894fe7b22a5c9c4b06',
    '13fbd79c3d390e5d6585a21e11ff5ec1970cff0c',
    '07c342be6e560e7f43842e2e21b774e61d85f047',
    '6b0d31c0d563223024da45691584643ac78c96e8',
    'd1854cae891ec7b29161ccaf79a24b00c274bdaa',
    '7a81af3e591ac713f81ea1efe93dcf36157d8376',
    '516b9783fca517eecbd1d064da2d165310b19759',
    '22ea1c649c82946aa6e479e1ffd321e4a318b1b0',
    '4dc7c9ec434ed06502767136789763ec11d2c4b7',
    'a0f1490a20d0211c997b44bc357e1972deab8ae3',
    '8efd86fb78a56a5145ed7739dcb00c78581c5375',
    '51e69892ab49df85c6230ccc57f8e1d1606caccc',
    '7a38d8cbd20d9932ba948efaa364bb62651d5ad4',
    'aff024fe4ab0fece4091de044c58c9ae4233383a',
    '11f6ad8ec52a2984abaafd7c3b516503785c2072',
    '95cb0bfd2977c761298d9624e4b4d4c72a39974a',
    '395df8f7c51f007019cb30201c49e884b46b92fa',
  ]
end
