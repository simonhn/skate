require 'rubygems'
require 'sinatra'
require 'haml'
require 'datamapper'
require 'flickraw-cached'
#require 'vimeo'
require 'builder'
require 'RedCloth'
#require 'dm-postgres-adapter'
#require 'newrelic_rpm'
require 'unicode'
#spot: et navn, en teaser tekst, en beskrivelses tekst, en geo lokation (latiture/longtitude), en adresse, et antal medier (foto, video), #links, en dato, et hashtag (saa folk kan twitte om netop det spot og vi kan evt. bruge det til at fetche flickr og youtube stuff der er #tagget med det tag? bare en ide). kan et spot forresten vaere en del af flere ruter?
#rute: samling af spots, en raekkefoelge af spots (saa vi ved hvordan vi skal tegne kortet), en beskrivelse, en teaser tekst.

class Spot
    include DataMapper::Resource
    property :id,           Serial, :key => true
    property :slug,         String
    property :title,        String
    property :teaser,       String, :length => 100
    property :body,         Text
    property :published_at, DateTime
    property :hashtag,      String, :length => 150
    property :address,      String, :length => 150
    property :lat,          Float
    property :long,         Float
    property :sequence,     Integer
    #has n, :photos, :through => Resource
    has n, :routes, :through => Resource

end

class Route
    include DataMapper::Resource
    property :id,           Serial, :key => true
    property :slug,         String
    property :title,        String
    property :teaser,      String, :length => 100
    property :body,     Text
    property :published_at, DateTime
    has n, :spots, :through => Resource
end


=begin
class Photo
    include DataMapper::Resource
    property :id,           Serial
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
=end

configure do
  #setup MySQL connection:  
  
  #DataMapper::Logger.new('log/datamapper.log', :debug)
  DataMapper.setup(:default, ENV['DATABASE_URL'] || 'mysql://pav.db')
  
  #@config = YAML::load( File.open( 'config/settings.yml' ) )
  #@connection = "#{@config['adapter']}://#{@config['username']}:#{@config['password']}@#{@config['host']}/#{@config['database']}";
  #DataMapper.setup(:default, @connection)
  DataMapper.finalize
  #drops table and rebuilds
  #DataMapper.auto_migrate!


  FlickRaw.api_key="f65cddc72218d6629231015dbba534ab"
  FlickRaw.shared_secret="02b67bec287635c1"
  set :haml, {:format => :html5}
end

helpers do
  
  def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Auth needed for post requests")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @user =  ENV['MY_SITE_USERNAME']
      @pass = ENV['MY_SITE_SECRET']
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [@user.to_s, @pass.to_s]
    end
    
    def slugalize(text, separator = "-")
        re_separator = Regexp.escape(separator)
        result = Unicode::decompose(text)
        result.gsub!(/[^\x00-\x7F]+/, '')                      # Remove non-ASCII (e.g. diacritics).
        result.gsub!(/[^a-z0-9\-_\+]+/i, separator)            # Turn non-slug chars into the separator.
        result.gsub!(/#{re_separator}{2,}/, separator)         # No more than one of the separator in a row.
        result.gsub!(/^#{re_separator}|#{re_separator}$/, '')  # Remove leading/trailing separator.
        result.downcase!
        result
      end
end

get '/' do  
  cache_control :public, :max_age => 600
  @route = Route.first
  @spots = @route.spots
  haml :map
end

get '/test/:slug' do
  slugalize(params[:slug])
end

get '/cloudmap' do
  @route = Route.first
  haml :cloudmap
end


get '/spot/new' do
  protected!
  
  @spot = Spot.new(params)
  @routes = Route.all
  haml :spot_form
end

get '/spot/:slug/delete' do
  protected!
  
  @spot = Spot.first(:slug => params[:slug])
  @spot.routes.destroy
  @spot.photos.destroy
  @spot.destroy!
  redirect '/'
end

post '/spot/new' do
  @spot = Spot.new(
    :slug       => slugalize(params["title"]),
    :title      => params["title"],
    :hashtag    => params["hashtag"],
    :teaser     => params["teaser"],
    :body       => params["body"],
    :lat        => params["lat"],
    :long       => params["long"],
    :sequence   => params["sequence"]
  )
  
  if @spot.save
     @route = Route.first(:slug => params[:route])
     @spot.routes << @route
     @spot.save
      redirect "/"
  else
    '/error'
  end
end

get '/spot/:slug/edit' do
  protected!
  
  @spot = Spot.first(:slug => params[:slug])
  raise not_found unless @spot
  @routes = Route.all
  haml :spot_form
end

post '/spot/:slug/edit' do
  @spot = Spot.first(:slug => params[:slug])
  raise not_found unless @spot
  
  @spot.attributes = {
    :title      => params["title"],
    :hashtag    => params["hashtag"],
    :teaser     => params["teaser"],
    :body       => params["body"],
    :lat        => params["lat"],
    :long       => params["long"],
    :sequence   => params["sequence"]
  }
  #@spot.routes << Route.first(:slug => params[:route])
    
  @spot.save
  redirect "/spot/#{@spot.slug}"
end

get '/spot/:slug' do
  cache_control :public, :max_age => 600
  @spot = Spot.first(:slug => params[:slug])
  @title = @spot.title
  @route = @spot.routes.first
  
  @spots = Spot.all
  #@videos = YouTube.all(:limit=>10)
  #@map = @spot.to_json(:methods => [:photos])
  @map = @spot.to_json

  #auth = flickr.auth.checkToken :auth_token => "72157624944961698-bc20f9c3f8e80ef5"
  #list = flickr.photos.search(:tags=>'skateboard,copenhagen',:per_page => 100, :tag_mode=> 'all', :sort => 'interestingness-desc')
  #info = flickr.photos.getInfo :photo_id => list[rand(list.size)].id
  #@url = FlickRaw.url_b(info)
  haml :spot
end

get '/route/:slug/edit' do
  protected!
  
  @route = Route.first(:slug => params[:slug])
  raise not_found unless @route
  haml :route_form
end

post '/route/:slug/edit' do
  
  @route = Route.first(:slug => params[:slug])
  raise not_found unless @route
  
  @route.attributes = {
    :title      => params["title"],
    :teaser     => params["teaser"],
    :body       => params["body"]
  }
    
  @route.save
  redirect "/"
end

get '/admin' do
  protected!
   @spots = Spot.all
   @routes = Route.all
   haml :admin
end

get '/georss.json' do
  cache_control :public, :max_age => 600
  
   @spots = Spot.all(:order => [:sequence.asc])
  @spots.to_json
end

get '/vimeo' do
  base = Vimeo::Advanced::Base.new("eecb2cd5c8a4c74f3380a5a5fa721d5f", "fd5e90a6fb18d6f5")
  request_token = base.get_request_token
  session[:oauth_secret] = request_token.secret
  redirect base.authorize_url
  
  base = Vimeo::Advanced::Base.new("eecb2cd5c8a4c74f3380a5a5fa721d5f", "fd5e90a6fb18d6f5")
  access_token = base.get_access_token(params[:oauth_token], session[:oauth_secret], params[:oauth_verifier])
  # You'll want to hold on to the user's access token and secret. I'll save it to the database.
  user.token = access_token.token
  puts user.token
  user.secret = access_token.secret
  puts user.secret
  
  #discover-1128959261
  
end

get '/populate' do
  #protected!   
  @spot1 = Spot.first_or_create({:slug => 'carlsberg'},{
          :title        => 'Carlsberg',
          :teaser       => 'Oeller',
          :body         => 'En lang beskrivelse af dette fantastiske sted, Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean dapibus odio a libero dapibus sit amet malesuada urna luctus. Integer eget metus mattis lacus scelerisque ultricies. Pellentesque cursus interdum purus, vestibulum viverra nulla mollis quis. Pellentesque dui orci, scelerisque ut rhoncus vel, scelerisque a est. Nam eget lectus lectus, sit amet aliquet eros. Nullam ac varius justo. Vestibulum sagittis fermentum urna sed accumsan. Nullam nisl ipsum, sodales non scelerisque vitae, dignissim sit amet felis. Praesent in magna et tortor sagittis consectetur porta vel risus. Nam sit amet feugiat velit. Vestibulum pretium posuere egestas. Sed est justo, euismod eu semper blandit, pulvinar at orci. Aenean facilisis volutpat sapien quis commodo. Suspendisse mollis placerat porttitor. Cras congue tellus a lorem rhoncus eu egestas nisi fermentum.',
          :hashtag      => 'carlsberg',
          :address       => 'ydre vesterbro',      
          :lat          => '55.665',
          :long         => '12.529972',
          :sequence        => '1'}
          )
 @spot2 = Spot.first_or_create({:slug => 'islandsbrygge'},{
         :title        => 'Islandsbrygge',
         :teaser       => 'Ved havnen',
         :body         => 'En lang body tekst, Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean dapibus odio a libero dapibus sit amet malesuada urna luctus. Integer eget metus mattis lacus scelerisque ultricies. Pellentesque cursus interdum purus, vestibulum viverra nulla mollis quis. Pellentesque dui orci, scelerisque ut rhoncus vel, scelerisque a est. Nam eget lectus lectus, sit amet aliquet eros. Nullam ac varius justo. Vestibulum sagittis fermentum urna sed accumsan. Nullam nisl ipsum, sodales non scelerisque vitae, dignissim sit amet felis. Praesent in magna et tortor sagittis consectetur porta vel risus. Nam sit amet feugiat velit. Vestibulum pretium posuere egestas. Sed est justo, euismod eu semper blandit, pulvinar at orci. Aenean facilisis volutpat sapien quis commodo. Suspendisse mollis placerat porttitor. Cras congue tellus a lorem rhoncus eu egestas nisi fermentum.',
         :hashtag      => 'islandsbrygge',
         :address       => 'Lige efter langbro',      
         :lat          => '55.6688',
         :long         => '12.5788',
         :sequence        => '2'}
         )
         


  @route = Route.first_or_create(
          :slug         => 'skate route nummer uno',
          :title        => 'En skate tur gennem cph',
          :teaser       => 'Klart den fedeste rute',
          :body         => 'En lang beskrivelse af denne fantastiske rute'
          )
  @route.save

  @spot1.routes << @route
  @spot2.routes << @route

  
  @spot1.save
  @spot2.save


end