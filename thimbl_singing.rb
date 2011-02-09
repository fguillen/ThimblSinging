require 'sinatra/base'
require 'thimbl'
require 'mustache/sinatra'

ROOT_PATH = File.dirname(__FILE__)

class ThimblSinging < Sinatra::Base
  FileUtils.mkdir( "#{ROOT_PATH}/caches" )  unless File.exists? "#{ROOT_PATH}/caches"
  
  register Mustache::Sinatra
  set :mustache, {
    :views     => 'views/',
    :templates => 'views/'
  }
  
  get '/' do
    mustache :new
  end
  
  get '/show' do
    redirect "/#{params[:thimbl_address]}/show"
  end

  get '/:thimbl_address/show' do
    thimbl = charge_thimbl params[:thimbl_address]
    
    @me = thimbl.data['me']
    @messages = thimbl.messages.reverse
    @following = thimbl.following
    
    mustache :show
  end
  
  get '/:thimbl_address/fetch' do
    thimbl = Thimbl::Base.new 'address' => params[:thimbl_address]
    thimbl.fetch  # me plan
    thimbl.fetch  # me following plans
    save_cache( thimbl.me, thimbl.data )
    
    redirect "/#{params[:thimbl_address]}/show"
  end
  
  def charge_thimbl( thimbl_address )
    thimbl = Thimbl::Base.new 'address' => thimbl_address
    if data = load_cache( thimbl_address )
      thimbl.data = data
    else 
      thimbl.fetch  # me plan
      thimbl.fetch  # me following plans
      save_cache( thimbl.me, thimbl.data )
    end
    
    return thimbl
  end

  # TODO: use better slugger
  def to_filename( thimbl_address )
    thimbl_address.gsub( '@', '_at_' )
  end
  
  def load_cache( thimbl_address )
    cache_file = "#{ROOT_PATH}/caches/#{to_filename thimbl_address}.json"
    return nil  unless File.exists? cache_file
    JSON.load File.read cache_file
  end

  
  def save_cache( thimbl_address, data )
    cache_file = "#{ROOT_PATH}/caches/#{to_filename thimbl_address}.json"
    File.open( cache_file, 'w' ) { |f| f.write data.to_json }
  end
end