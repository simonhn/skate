require "rubygems"
require "datamapper"
#require "dm-core"
require "flickraw-cached"
#require "vimeo"
require 'youtube_g'
require  'dm-migrations'


class Photo
    include DataMapper::Resource
    property :id,           Serial, :key => true
    property :title,        String
    property :summary,      String, :length => 100
    property :flick_id,     String, :length => 100
    property :url,          String, :length => 256
    property :url_m,        String, :length => 256
    property :url_s,        String, :length => 256
    property :url_t,        String, :length => 256
    property :url_b,        String, :length => 256
    property :url_z,        String, :length => 256
    property :url_o,        String, :length => 256
    property :type,         String, :length => 100
    #has n, :spots, :through => Resource
end

class YouTube
    include DataMapper::Resource
    property :id,           Serial, :key => true
    property :title,        String
    property :yt_id,        String, :length => 100
    property :img_url,      String, :length => 256
    property :type,         String, :length => 100
    property :embed_html,   Text
end

def configure
  #setup MySQL connection:  
  @config = YAML::load( File.open( 'settings.yml' ) )
  @connection = "#{@config['adapter']}://#{@config['username']}:#{@config['password']}@#{@config['host']}/#{@config['database']}";
  DataMapper.setup(:default, @connection)
  DataMapper.auto_upgrade!
  #drops table and rebuilds
  #DataMapper.auto_migrate!
  FlickRaw.api_key="26a3aea48d909153a7e4867c6155c00a"
  FlickRaw.shared_secret="1f521014a6c266e9"
end

def flickra

  auth = flickr.auth.checkToken :auth_token => "72157624944961698-bc20f9c3f8e80ef5"
  list = flickr.photos.search(:tags=>'skateboard,copenhagen',:per_page => 100, :tag_mode=> 'all', :sort => 'interestingness-desc')
  #puts list.inspect
  list.each do |item|
    info = flickr.photos.getInfo :photo_id =>item.id
    @media = Photo.first_or_create({:title => item.title},{
      :title    => item.title,
      :summary  => 'description',
      :flick_id => item.id,
      :url      => FlickRaw.url(item),
      :url_m    => FlickRaw.url_m(item),
      :url_s    => FlickRaw.url_s(item),
      :url_t    => FlickRaw.url_t(item),
      :url_b    => FlickRaw.url_b(item),
      :url_z    => FlickRaw.url_z(item),
      :type     => 'flickr'}
    )
    @media.save
  end
  #info = flickr.photos.getInfo :photo_id => list[rand(list.size)].id
  #@url = FlickRaw.url_b(info)
  
end



def vimeo
  video = Vimeo::Advanced::Video.new("consumer_key", "consumer_secret", :token => "1128959261", :secret => "discover")
  hat = video.search("query", { :page => "1", :per_page => "25", :full_response => "0", :sort => "newest", :user_id => nil })
  puts hat.inspect
 # discover-1128959261
end

def youtube
  client = YouTubeG::Client.new
  result = client.videos_by(:query => "skateboard copenhagen")
  result.videos.each{|item|
    @yt = YouTube.first_or_create({:title => item.title},{
      :title      => item.title,
      :yt_id      => item.unique_id,
      :img_url    => item.thumbnails.first.url,
      :type       => 'youtube',
      :embed_html => item.embed_html }
    )
    @yt.save
  }
end
configure
flickra
#vimeo
youtube