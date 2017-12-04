require 'find'

$file_path="test/pdf2"

$requiredDocs=["AADHAAR","PROPERTY_DOCUMENT","MOBILE_BILL","BANK_STATEMENT","PAYSLIP","DRIVING_LICENSE","PASSPORT","PAN","VOTER_ID","FORM16",
                 "GAS_BILL","WATER_BILL","ELECTRICITY_BILL","LANDLINE_BILL","FORM26_AS","APPLICATION_PDF",
                 "EMPLOYMENT_VERIFICATION","ApplicationSummaryReport"]

$sysdocMapMiniMalImg=Hash.new
$sysdocMapMiniMalImg["AADHAAR"]=false
$sysdocMapMiniMalImg["PROPERTY_DOCUMENT"]=false
$sysdocMapMiniMalImg["MOBILE_BILL"]=false
$sysdocMapMiniMalImg["BANK_STATEMENT"]=false #true
$sysdocMapMiniMalImg["PAYSLIP"]=false
$sysdocMapMiniMalImg["DRIVING_LICENSE"]=false
$sysdocMapMiniMalImg["PAN"]=false
$sysdocMapMiniMalImg["VOTER_ID"]=false
$sysdocMapMiniMalImg["FORM16"]=false
$sysdocMapMiniMalImg["GAS_BILL"]=false
$sysdocMapMiniMalImg["WATER_BILL"]=false
$sysdocMapMiniMalImg["ELECTRICITY_BILL"]=false
$sysdocMapMiniMalImg["LANDLINE_BILL"]=false
$sysdocMapMiniMalImg["FORM26_AS"]=true
$sysdocMapMiniMalImg["APPLICATION_PDF"]=true
$sysdocMapMiniMalImg["EMPLOYMENT_VERIFICATION"]=true
$sysdocMapMiniMalImg["ApplicationSummaryReport"]=true


def populate_files(regex)
  puts "Checking for #{regex}"
  #collecting the filespaths
  file_paths = []
  Find.find($file_path) do |path|
    file_paths << path if path =~ regex #/.*\.pdf$|.*\.PDF$/
    puts "Found - #{file_paths}"
  end
  return file_paths
end



#       System doc | Customer upload
#        /      |-----|           \
#   text PDF | Image PDF | Text + Image PDF
#      |               \    |
#   gs pdf->tiff(lzw) | imagemagick jpeg
#
# We can convert PDF to tiff and apply LZW (Lemple-Zif-Welch) to system
# docs with only grayscale text or images with large areas of single color
#
# LZW (Lemple-Zif-Welch)
# Lossless compression; supported by TIFF, PDF, GIF, and PostScript language file formats. Most useful for images with large areas of single color.
#
# else First convert all PDF, page by page to JEPG, which offers better
# compression with a relatively good quality image and upload it to CMS
#
# For all append(combining images), if any, use tiff as the final format as
# as it has higher resolution limit than JPEG
#
# It is observed that JPEG to TIFF is not as explosive in terms of
# size as PDF to TIFF
#
def file_converter()
  pdf_files = populate_files(/.*\.pdf$|.*\.PDF$/)

  #converting pdf to jpg then to tiff
  pdf_files.each { |pdf_file|

    required = false;
    key = pdf_file
    $requiredDocs.each do |requiredFileName|
      if(pdf_file.include?(requiredFileName))
        required=true
        key = requiredFileName
      end
    end

    next if !required

    jpg_file = pdf_file.chomp('.pdf').chomp('.PDF').chomp('.png') + '.jpg'
    gs_tiff_file = pdf_file.chomp('.pdf').chomp('.PDF').chomp('.png')

    if $sysdocMapMiniMalImg[key] == false
      jpg_file=jpg_file.split(".")[0] << "_converted."+jpg_file.split(".")[1]
      jpg_file_name = File.basename jpg_file, ".jpg"
      puts "converted file name #{jpg_file_name}"

      #command to convert pdf to jpg
      convertCmdJPG = "convert -strip -density  150  \"#{pdf_file}\"  -quality 30 -colorspace Gray \"#{jpg_file}\""
      # both image and text quality is maintained	
      #gs -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 -sDEVICE=tiffgray -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r120 -sCompression=lzw -dBackgroundColor=16#ffffff -sOutputFile=AADHAAR_manual4.tiff AADHAAR.PDF
      # text quality maintained but image quality suffers
      #gs -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 -sDEVICE=tiffg4 -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r120 -sCompression=lzw -dBackgroundColor=16#ffffff -sOutputFile=AADHAAR_manual5.tiff AADHAAR.PDF
      # for very high resolution images use the below to flags
      # -sPAPERSIZE=a4 -dFitPage  
      # tmp convert to png
      # gs -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 -sDEVICE=pnggray -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r150 -dCompatibilityLevel=1.4 -sCompression=lzw -sPAPERSIZE=a4 -dFitPage -dBackgroundColor=16#ffffff -sOutputFile=BANK_STATEMENT-150-tmp-%02d.png BANK_STATEMENT.PDF
      # convert the png to jpeg with 20% compression
      # convert -verbose -density 150 BANK_STATEMENT-150-tmp-*.png -quality 80 BANK_STATEMENT-150-80-tmp-%02d.jpg

      # convert directly to pnggray from ghost script
      # gs -q -dQUIET -dSAFER -dBATCH -dNOPAUSE -dNOPROMPT -dMaxBitmap=500000000 -dAlignToPixels=0 -dGridFitTT=2 -sDEVICE=jpeggray -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -r150  -sCompression=lzw  -dFitPage -dBackgroundColor=16#ffffff -dJPEGQ=50 -sOutputFile=APPLICATION_PDF-r120-30-jgray-clzw-%02d.jpg APPLICATION_PDF.pdf

      #%x is used to run from shell
      %x(#{convertCmdJPG})


      converted_file_path= populate_files(/.*#{jpg_file_name}*.jpg$/)
      #if pdf has one or more page then convert will create new no of files depend on the pages.So combining them those one. So that when uploading it wont cause confusion
      puts "Number of Converted files - #{converted_file_path.size()}"
      if converted_file_path.size() == 0
        converted_file_path= populate_files(/.*#{jpg_file_name}-*[0-9].jpg$/)
        puts "Number of Converted files - #{converted_file_path.size()}"
      end

      # if the page count is more than N, two things can
      # happen :-
      # 1. CMS upload will fail
      # 2. If we try to combine the jpg to a single jpg, max resolution exceeded error will pop up

      if converted_file_path.size > 40
        puts "Page limit exceeded. This request will fail"
        # TODO send out error PAGE_LIMIT_EXCEEDED
      end
      converted_file_path.each_with_index { |jpg, fileCount|
        #all_jpg_files = "#{jpg_file_name}-*[0-9][0-9].jpg"
        #puts "All JPG Files - #{all_jpg_files}"
        #combine_jpg_file = "#{jpg_file_name}-combined.jpg"
        #puts "Combined file - #{combine_jpg_file}"
        #combineCmd = "convert \"#{all_jpg_files}\" -append \"#{combine_jpg_file}\" "
        #command to combine all the jpg
        #%x(#{combineCmd})

        # convert to tiff or
        # TODO upload to cms one by one

        #tiff_file = jpg.chomp('.jpg').chomp('.JPG').chomp('.JPEG').chomp('.jpeg').chomp('.png') + '.tiff'
        #tiff_file=tiff_file.split(".")[0] << "_converted."+tiff_file.split(".")[1]
        #tiff_file_name = File.basename tiff_file, ".tiff"
        #puts "converted file name #{tiff_file}"

        #command to convert jpg to tiff
        #convertCmdTIFF = "convert -strip  \"#{jpg}\"  \"#{tiff_file}\""
        #%x is used to run from shell
        #%x(#{convertCmdTIFF})
      }

      # combine if one pdf generated multiple jpg/tiff
      #if converted_file_path.size()> 1
      #  all_tiff_files = $file_path + "/*#{jpg_file_name}*.tiff"
      #  combine_tiff_file = $file_path+"/#{jpg_file_name}-combined.tiff"
      #  combineCmd = "convert -append \"#{all_tiff_files}\"  \"#{combine_tiff_file}\" "
      #  #command to combine all the jpeg to a final tiff
      #  %x(#{combineCmd})
      #end
    else
      # Using Ghost script
      # command to convert PDF to tiff
      convertCmdgsTIFF = "gs -q -dNOPAUSE -sDEVICE=tiffgray -r150 -sCompression=lzw  -sOutputFile='#{gs_tiff_file}-%02d.tiff' #{pdf_file} -c quit"
      #%x is used to run from shell
      %x(#{convertCmdgsTIFF})
      # TODO if resolution is more than A4 r=120/900x1400 then resize it to A4
      # TODO upload to cms
    end
  }

  #all_converted_files = $file_path + "/*_converted.tiff"
  #all_combined_files = $file_path + "/*_converted-combined.tiff"
  #final_file = $file_path+"/converted-final.tiff"
  #puts "Final tiff files"
  #populate_files(all_converted_files)
  #populate_files(all_combined_files)
  #combineCmd = "convert -append \"#{all_converted_files}\" \"#{all_combined_files}\" \"#{final_file}\" "
  #command to combine all the tiff
  #%x(#{combineCmd})

end


file_converter
