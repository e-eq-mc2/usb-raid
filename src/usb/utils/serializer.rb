module Usb::Utils::Serializer
  DEFAULT_FORMAT = :json

  FORMAT2CONTENT_TYPE = {
    json:    'application/json',
    msgpack: 'application/x-msgpack',
    binary:  'application/octet-stream',
    marshal: 'application/octet-stream',
  }

  class << self
    def availables
      FORMAT2CONTENT_TYPE.keys
    end

    def available?(format)
      availables.include?(format)
    end

    def pack(data, format: DEFAULT_FORMAT)
      str = 
        case format
        when :json    then JSON.dump(data)
        when :msgpack then MessagePack.pack(data, encoding: Encoding::ASCII_8BIT)
        when :marshal then Marshal.dump(data)
        when :binary  then data
        else fail
        end
    end

    def unpack(str, format: DEFAULT_FORMAT, symbolize_keys: true)
      data = 
        case format
        when :json    then JSON.parse(str)
        when :msgpack then MessagePack.unpack(str, encoding: Encoding::ASCII_8BIT)
        when :marshal then Marshal.load(str)
        when :binary  then str
        else fail
        end

      if symbolize_keys && [:json, :msgpack].include?(format)
        deep_symbolize_keys(data)
      else
        data
      end
    end

    def deep_symbolize_keys(data)
      case data
      when Hash  
        data.deep_symbolize_keys!
      when Array 
        tmp = {data: data}
        tmp.deep_symbolize_keys!
        data = tmp[:data]
      else data
      end
    end

    def format2content_type(format)
      FORMAT2CONTENT_TYPE[format] #|| fail
    end

    def content_type2format(content_type)
      FORMAT2CONTENT_TYPE.each {|k,v| return k if content_type =~ /#{v}/}
      nil
    end
  end
end
