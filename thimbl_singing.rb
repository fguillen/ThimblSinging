require 'rubygems'
require 'sinatra/base'
require 'thimbl'
require 'mustache/sinatra'

ROOT_PATH = File.dirname(__FILE__)

class ThimblSinging < Sinatra::Base
  register Mustache::Sinatra
  set :mustache, {
    :views     => "#{File.dirname(__FILE__)}/views/",
    :templates => "#{File.dirname(__FILE__)}/views/"
  }
  
  # activate
  get '/' do
    mustache :new
  end
  
  # redirect to show
  get '/show' do
    redirect "/#{params[:thimbl_user]}/show"
  end

  # show
  get '/:thimbl_user/show' do
    thimbl = ThimblSinging.charge_thimbl params[:thimbl_user]
    
    @me = thimbl.me
    @messages = thimbl.messages.reverse
    @following = thimbl.following
    @last_fetch = File.atime "#{ThimblSinging.caches_path}/#{ThimblSinging.to_filename params[:thimbl_user]}.json"
    
    mustache :show
  end
  
  # fetch
  get '/:thimbl_user/fetch' do
    thimbl = Thimbl::Base.new 'address' => params[:thimbl_user]
    thimbl.fetch  # me plan
    thimbl.fetch  # me following plans
    ThimblSinging.save_cache( thimbl.me, thimbl.data )
    
    redirect "/#{params[:thimbl_user]}/show"
  end
  
  # post
  post '/:thimbl_user/post' do
    thimbl = ThimblSinging.charge_thimbl params[:thimbl_user]
    thimbl.post!( params[:text], params[:password] )
    ThimblSinging.save_cache( thimbl.me, thimbl.data )
    
    redirect "/#{params[:thimbl_user]}/show"
  end
  
  # follow
  post '/:thimbl_user/follow' do
    thimbl = ThimblSinging.charge_thimbl params[:thimbl_user]
    thimbl.follow!( params[:nick], params[:address], params[:password] )
    thimbl.fetch
    ThimblSinging.save_cache( thimbl.me, thimbl.data )
    
    redirect "/#{params[:thimbl_user]}/show"
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

  # TODO: use better slugger
  def self.to_filename( thimbl_user )
    thimbl_user.gsub( '@', '_at_' )
  end
  
  def self.load_cache( thimbl_user )
    cache_path = "#{ThimblSinging.caches_path}/#{ThimblSinging.to_filename thimbl_user}.json"
    return nil  unless File.exists? cache_path
    JSON.load File.read cache_path
  end

  def self.save_cache( thimbl_user, data )
    FileUtils.mkdir( ThimblSinging.caches_path )  unless File.exists? ThimblSinging.caches_path
    cache_path = "#{ThimblSinging.caches_path}/#{ThimblSinging.to_filename thimbl_user}.json"
    File.open( cache_path, 'w' ) { |f| f.write data.to_json }
  end
  
  def self.caches_path
    "#{ROOT_PATH}/caches"
  end
end