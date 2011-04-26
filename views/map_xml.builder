xml.instruct! :xml, :version => '1.0'
xml.markers do
  @spots.each do |spot|
    xml.marker do
      xml.name spot.title
      xml.address spot.address
      xml.lat spot.lat
      xml.long spot.long
    end
  end
end