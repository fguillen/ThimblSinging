module ThimblSinging 
  class App < Sinatra::Base
    register Mustache::Sinatra
    
    require File.expand_path( "#{File.dirname(__FILE__)}/../views/layout" )
    
    set :sessions, true  unless test?
    set :loggin, true
    set :public, File.expand_path( "#{File.dirname(__FILE__)}/../../public" )
    set :mustache, {
      :views     => File.expand_path( "#{File.dirname(__FILE__)}/../views/" ),
      :templates => File.expand_path( "#{File.dirname(__FILE__)}/../templates/" )
    }
  
    before /\/(timeline|timeline_fetch|post|follow|unfollow)\/?/ do
      if( session[:address].nil? )
        puts "Warn: not user logged"  unless ThimblSinging::App.test?
        @message = "You need to be logged in :/"
        redirect '/'
      end
    end
    
    # root
    get '/' do
      if( session[:address].nil? )
        redirect "/global_timeline"
      else
        redirect "/timeline"
      end
    end
  
    post '/login' do
      user      = params[:address].split('@')[0]
      server    = params[:address].split('@')[1]
      password  = params[:password] || ""
    
      begin
        Net::SSH.start(server, user, :password => password) {}
        ThimblSinging::Utils.charge_thimbl( params[:address] )
        
        session[:address] = params[:address]
        session[:password] = params[:password]

        redirect "/timeline"
      rescue Exception => e
        puts "Warn: Authentication error with user: '#{params[:address]}', e: '#{e.message}'"
        @message = "Error trying to validate user :/"
        redirect( '/global_timeline' )
      end
    end
  
    get '/logout' do
      session[:address] = nil
      session[:password] = nil
      redirect '/'
    end

    # timeline
    get '/timeline' do
      @thimbl = ThimblSinging::Utils.charge_thimbl( session[:address] )
      @last_fetch = ThimblSinging::Utils.last_fetch( session[:address] )
      @timeline = ThimblSinging::Utils.charge_timeline( @thimbl.address )
    
      load_view_variables
      mustache :timeline
    end
  
    # update user's cache and all user's following cache
    get '/timeline_fetch' do
      ThimblSinging::Utils.charge_timeline( session[:address], true )
      redirect '/timeline'
    end
  
    # global timeline
    get '/global_timeline' do
      @last_fetch = ThimblSinging::Utils.last_global_fetch
      @timeline = ThimblSinging::Utils.charge_global_timeline
    
      load_view_variables
      mustache :global_timeline
    end
  
    # update all known users caches
    get '/global_timeline_fetch' do
      ThimblSinging::Utils.charge_global_timeline( true )
      redirect '/global_timeline'
    end  
  
    # post
    post '/post' do
      thimbl = ThimblSinging::Utils.charge_thimbl( session[:address], true )
      thimbl.post!( params[:text], session[:password] )
      ThimblSinging::Utils.save_cache( thimbl.address, thimbl.data )
    
      redirect "/timeline"
    end
  
    # follow
    post '/follow' do
      if( !params[:address].nil? && params[:address] != '' )
        thimbl = ThimblSinging::Utils.charge_thimbl( session[:address], true )
        thimbl.follow!( params[:nick], params[:address], session[:password] )
        ThimblSinging::Utils.save_cache( thimbl.address, thimbl.data )
      end
    
      redirect "/timeline"
    end
  
    # unfollow
    post '/unfollow' do
      thimbl = ThimblSinging::Utils.charge_thimbl( session[:address], true )
      thimbl.unfollow!( params[:address], session[:password] )
      ThimblSinging::Utils.save_cache( thimbl.address, thimbl.data )
    
      redirect "/timeline"
    end

    # profile
    get '/:address' do
      @thimbl = ThimblSinging::Utils.charge_thimbl( params[:address] )
      @last_fetch = ThimblSinging::Utils.last_fetch( params[:address] )
    
      # feeding the known_users list
      ThimblSinging::Utils.charge_thimbls( @thimbl.following.map( &:address ) )
      
      load_view_variables
      
      mustache :profile
    end
  
    # fetch update the user's cache
    get '/:address/fetch' do
      thimbl = ThimblSinging::Utils.charge_thimbl( params[:address], true )
      redirect "/#{params[:address]}"
    end
  
    def load_view_variables
      @known_users = ThimblSinging::Utils.known_users
      @session = session
    end
  end
end