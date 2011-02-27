require 'rubygems'
require 'sinatra/base'
require 'thimbl'
require 'mustache/sinatra'
require 'net/ssh'

ROOT_PATH = File.dirname(__FILE__)

class ThimblSinging < Sinatra::Base
  enable :sessions
  register Mustache::Sinatra
  set :mustache, {
    :views     => "#{File.dirname(__FILE__)}/views/",
    :templates => "#{File.dirname(__FILE__)}/views/"
  }
  
  set :public, "#{File.dirname(__FILE__)}/public"
  
  # root
  get '/' do
    load_view_variables
    mustache :new
  end
  
  post '/login' do
    user      = params[:user].split('@')[0]
    server    = params[:user].split('@')[1]
    password  = params[:password] || ""
    
    begin
      Net::SSH.start(server, user, :password => password) {}
      session[:user] = params[:user]
      session[:password] = params[:password]
      redirect "/#{session[:user]}"
    rescue Net::SSH::AuthenticationFailed, SocketError, Errno::ECONNREFUSED
      @message = "Error trying to validate user :/"
      load_view_variables
      mustache :new
    end
  end
  
  get '/logout' do
    session[:user] = nil
    session[:password] = nil
    redirect '/'
  end
  
  # redirect to show
  get '/show' do
    redirect "/#{params[:thimbl_user]}"
  end
  
  # show.json
  get %r{/(.*)\.json} do |thimbl_user|
    thimbl = ThimblSinging.charge_thimbl thimbl_user
    content_type :json
    thimbl.plan.to_json
  end

  # show
  get '/:thimbl_user' do
    @thimbl = ThimblSinging.charge_thimbl params[:thimbl_user]
    @last_fetch = ThimblSinging.last_fetch params[:thimbl_user]
    
    load_view_variables
    mustache :show
  end
  
  # fetch
  get '/:thimbl_user/fetch' do
    thimbl = Thimbl::Base.new 'address' => params[:thimbl_user]
    thimbl.fetch  # me plan
    thimbl.fetch  # me following plans
    ThimblSinging.save_cache( thimbl.me, thimbl.data )
    
    redirect "/#{params[:thimbl_user]}"
  end
  
  # post
  post '/:thimbl_user/post' do
    thimbl = ThimblSinging.charge_thimbl params[:thimbl_user]
    thimbl.post!( params[:text], session[:password] )
    ThimblSinging.save_cache( thimbl.me, thimbl.data )
    
    redirect "/#{params[:thimbl_user]}"
  end
  
  # follow
  post '/:thimbl_user/follow' do
    puts "XXX: pass: #{session[:password]}"
    thimbl = ThimblSinging.charge_thimbl params[:thimbl_user]
    thimbl.follow!( params[:nick], params[:address], session[:password] )
    thimbl.fetch
    ThimblSinging.save_cache( thimbl.me, thimbl.data )
    
    redirect "/#{params[:thimbl_user]}"
  end
  
  def self.charge_thimbl( thimbl_user )
    thimbl = Thimbl::Base.new 'address' => thimbl_user
    if data = ThimblSinging.load_cache( thimbl_user )
      thimbl.data = data
    else 
      thimbl.fetch  # me plan
      thimbl.fetch  # me following plans
      ThimblSinging.save_cache( thimbl.me, thimbl.data )
    end
    
    return thimbl
  end
  
  def load_view_variables
    @known_users = ThimblSinging.known_users
    @session = session
  end

  # TODO: use better slugger
  def self.to_filename( thimbl_user )
    thimbl_user.gsub( '@', '_at_' )
  end
  
  def self.load_cache( thimbl_user )
    cache_path = "#{ThimblSinging.caches_path}/#{ThimblSinging.to_filename thimbl_user}.json"
    return nil  unless File.exists? cache_path
    return JSON.load File.read cache_path
  end

  def self.save_cache( thimbl_user, data )
    FileUtils.mkdir( ThimblSinging.caches_path )  unless File.exists? ThimblSinging.caches_path
    cache_path = "#{ThimblSinging.caches_path}/#{ThimblSinging.to_filename thimbl_user}.json"
    File.open( cache_path, 'w' ) { |f| f.write data.to_json }
  end
  
  def self.last_fetch( thimbl_user )
    File.mtime "#{ThimblSinging.caches_path}/#{ThimblSinging.to_filename thimbl_user}.json"
  end
  
  def self.known_users
    result = []
    Dir["#{ThimblSinging.caches_path}/*_at_*.json"].each do |cache_path|
      known_user_user_name = JSON.load( File.read cache_path )['me']
      known_user_last_fetch = ThimblSinging.last_fetch known_user_user_name
      result << { 'address' => known_user_user_name, 'last_fetch' => known_user_last_fetch }
    end
    
    return result
  end
  
  def self.caches_path
    "#{ROOT_PATH}/caches"
  end
end