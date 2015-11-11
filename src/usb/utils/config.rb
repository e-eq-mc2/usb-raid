module Usb::Utils::Config
  class << self
    def load(path)
      if File.exists?(path)
        hash = YAML.load_file(path)

        hash.deep_symbolize_keys unless hash.nil?
      else
        hash = nil
      end
    end

    def save(path, hash)
      str = YAML.dump(hash)
      File.open(path, 'w') {|f| f.write str} #Store
    end
  end
end
