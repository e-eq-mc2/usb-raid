module Usb::Utils::URI
  def self.build(params)
    case params[:scheme]
    when 'http'  then URI::HTTP.build(params).to_s
    when 'https' then URI::HTTPS.build(params).to_s
    else fail
    end
  end
end
