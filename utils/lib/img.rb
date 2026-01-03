require 'rmagick'

class ImgManager
  def self.mkpixel(r5,g5,b5,tp=false)
    tp ?
      Magick::Pixel.new(r5*2048, g5*2048, b5*2048, 65535) :
      Magick::Pixel.new(r5*2048, g5*2048, b5*2048)
  end
end

