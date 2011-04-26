xml.instruct! :xml, :version => '1.0', :standalone => 'yes'
xml.feed :xmlns=>"http://www.w3.org/2005/Atom", "xmlns:geo"=>"http://www.w3.org/2003/01/geo/wgs84_pos#", "xmlns:georss"=>"http://www.georss.org/georss" do
xml.title 'skate spots in cph' 
xml.link :href=>"http://example.org/"
  @spots.each do |spot|
    xml.entry do
      xml.title spot.title
      xml.address spot.address
      xml.content :type=>'html'
      xml.geo :lat, spot.lat
      xml.geo :long, spot.long
      xml.georss :point do
        xml.text! spot.lat.to_s + ' ' + spot.long.to_s
      end
    end
  end
end