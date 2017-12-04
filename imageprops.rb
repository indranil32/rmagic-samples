require 'rmagick'


#require 'mini_magick'
#image = Magick::ImageList.new("/home/indranilm/Pictures/cms_prod_user.png")[0]
#image = Magick::Image.ping( '/home/indranilm/Pictures/cms_prod_user.png' ).first
#image = MiniMagick::Image.open("/home/indranilm/Documents/roboArm/60149449_1494482729123.pdf")
# image = MiniMagick::Image.open("/home/indranilm/Pictures/cms_prod_user.png")
#puts image.properties;
#puts "type #{image.mime_type}"   #=> "image/jpeg"
#puts "width #{image.width}"       #=> 250
#puts "height #{image.height}"      #=> 300
#puts "width  #{image.columns}"
#puts "height  #{image.rows}"
#puts "dimensions #{image.dimensions}"  #=> [250, 300]
#puts "size(in bytes) #{image.size}"        #=> 3451 (in bytes)
#puts "colorspace #{image.colorspace}"  #=> "DirectClass sRGB"
#puts "exif #{image.exif}"        #=> {"DateTimeOriginal" => "2013:09:04 08:03:39", ...}
#puts "resolution #{image.resolution}"  #=> [75, 75]
#puts "signature #{image.signature}"   #=> "60a7848c4ca6e36b8e2c5dea632ecdc29e9637791d2c59ebf7a54c0c6a74ef7e"


max_page_count = 44

images = Magick::Image::read('test/pdf1/APPLICATION_PDF.pdf')#BANK_STATEMENT.PDF')#.first
#puts images
images.each_with_index { |image, index |

  if index > max_page_count
    puts 'Max page limit reached!'
    break
  end

  puts "   Format: #{image.format}"
  puts "   Geometry: #{image.columns}x#{image.rows}"
  puts '   Class: ' + case image.class_type
                        when Magick::DirectClass
                          "DirectClass"
                        when Magick::PseudoClass
                          "PseudoClass"
                      end
  puts "   Depth: #{image.depth} bits-per-pixel"
  puts "   Colors: #{image.number_colors}"
  puts "   Filesize: #{image.filesize}"
  puts "   Resolution: #{image.x_resolution.to_i}x#{image.y_resolution.to_i} "+
           "pixels/#{image.units == Magick::PixelsPerInchResolution ?
               "inch" : "centimeter"}"
  if image.properties.length > 0
    puts "   Properties:"
    image.properties { |name,value|
      puts %Q|      #{name} = "#{value}"|
    }
  end

  #image.display
  #image.write("#{index}.pdf")
  #image.colorspace=Magick::GRAYColorspace
  #image.compression=Magick::LZWCompression#

  #image = image.quantize(256,Magick::GRAYColorspace) #, dither=NoDitherMethod);
  #image.write("#{index}.jpg") {
  #  self.quality = 100
  #  self.colorspace = Magick::GRAYColorspace
  #  #self.compression = Magick::JPEG2000Compression#ZipCompression##LZWCompression
  #  #self.density = 150
  #}

  #jpg = Magick::Image::read("#{index}.jpg").first
  #jpg.display

  #image.write("#{index}.tiff") {
  #  self.quality = 50
  #  self.colorspace = Magick::GRAYColorspace
  #  self.compression = Magick::LZWCompression
  #  #self.opacity = 0
  #  #  self.density = 150
  #}

  #tiff = Magick::Image::read("#{index}.tiff").first
  #tiff.display
}

exit
