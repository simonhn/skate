require 'rubygems'
require 'sinatra'
require 'haml'
require 'dm-core'
require 'dm-serializer'
require 'dm-timestamps'
require 'dm-aggregates'
require 'dm-migrations'
require 'flickraw-cached'
require 'builder'
require 'RedCloth'
require 'unicode'

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

configure do
  #logging:
  #DataMapper::Logger.new('log/datamapper.log', :debug)
  
  #setup MySQL connection:  
  DataMapper.setup(:default, ENV['DATABASE_URL'] || 'mysql://pav.db')
  
  #for localhost db connection
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
  #@spot.photos.destroy
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
  @spot.save
  redirect "/spot/#{@spot.slug}"
end

get '/spot/:slug' do
  cache_control :public, :max_age => 600
  @spot = Spot.first(:slug => params[:slug])
  @title = @spot.title
  @route = @spot.routes.first  
  @spots = Spot.all
  @map = @spot.to_json
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