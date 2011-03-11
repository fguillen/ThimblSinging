require "#{File.dirname(__FILE__)}/test_helper"

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    ThimblSinging::App.new
  end

  def test_root_redirect_to_global_timeline
    get '/'
    assert( last_response.redirect? )
    assert_match( '/global_timeline', last_response.location )
  end
  
  def test_root_redirect_to_timeline_if_user_loged
    get '/', {}, { 'rack.session' => { :address => 'me@thimbl.net' } }
    assert( last_response.redirect? )
    assert_match( '/timeline', last_response.location )
  end

  def test_show_login_if_not_logged
    ThimblSinging::App.any_instance.expects( :load_view_variables )
    get '/global_timeline'
    assert_match( /div id="login"/, last_response.body )
  end

  def test_not_show_login_iflogged
    ThimblSinging::Utils.stubs( :known_users ).returns( [] )
    thimbl = Thimbl::Base.new( 'me@thimbl.net' )
    ThimblSinging::Utils.stubs( :charge_thimbl ).with( thimbl.address ).returns( thimbl )
    
    get '/global_timeline', {}, { 'rack.session' => { :address => thimbl.address } }
    
    assert_match( "welcome", last_response.body )
  end
  
  def test_login
    Net::SSH.expects( :start ).with('thimbl.net', 'me', :password => 'pass').returns( true )
    thimbl = Thimbl::Base.new( 'me@thimbl.net' )
    ThimblSinging::Utils.stubs( :charge_thimbl ).with( thimbl.address ).returns( thimbl )

    session = {}
    post '/login', {:address => thimbl.address, :password => 'pass'}, {'rack.session' => session}

    assert_equal( thimbl.address, session[:address] )
    assert_equal( 'pass', session[:password] )
    
    assert( last_response.redirect? )
    assert_match( "/timeline", last_response.location )
  end

  def test_profile
    ThimblSinging::Utils.stubs( :caches_path ).returns( "#{FIXTURES_PATH}/caches" )
    
    get "/me@thimbl.net"

    # File.open( '/tmp/exit.html', 'w' ) { |f| f.write last_response.body }
      
    assert_match( 'User Name', last_response.body )
    assert_match( 'User Bio', last_response.body )
    assert_match( 'user email', last_response.body )
    assert_match( 'user mobile', last_response.body )
    assert_match( 'user website', last_response.body )

    assert_match( 'message 1', last_response.body )
    assert_match( 'one@thimbl.net', last_response.body )
  end
  
  def test_timeline
    ThimblSinging::Utils.stubs( :caches_path ).returns( "#{FIXTURES_PATH}/caches" )
    
    get "/timeline", {}, { 'rack.session' => { :address => 'me@thimbl.net' } }

    # File.open( '/tmp/exit.html', 'w' ) { |f| f.write last_response.body }

    assert_match( 'message 1', last_response.body )
    assert_match( 'user a message 1', last_response.body )
    assert_match( 'one@thimbl.net', last_response.body )
  end
  
  def test_timeline_fetch
    ThimblSinging::Utils.expects( :charge_timeline ).with( 'me@thimbl.net', true )
    
    get '/timeline_fetch', {}, { 'rack.session' => { :address => 'me@thimbl.net' } }
    
    assert( last_response.redirect? )
    assert_match( "/timeline", last_response.location )
  end
  
  def test_global_timeline
    ThimblSinging::Utils.stubs( :caches_path ).returns( "#{FIXTURES_PATH}/caches" )
    
    get "/global_timeline"

    # File.open( '/tmp/exit.html', 'w' ) { |f| f.write last_response.body }

    assert_match( 'message 1', last_response.body )
    assert_match( 'user a message 1', last_response.body )
  end
  
  def test_global_timeline_fetch
    ThimblSinging::Utils.expects( :charge_global_timeline ).with( true )
    
    get '/global_timeline_fetch'
    
    assert( last_response.redirect? )
    assert_match( "/global_timeline", last_response.location )
  end
  
  def test_post
    thimbl = Thimbl::Base.new 'user@thimbl.net'
    ThimblSinging::Utils.expects( :charge_thimbl ).with( thimbl.address, true ).returns( thimbl )
    thimbl.expects( 'post!' ).with( 'message', 'pass' )
    ThimblSinging::Utils.expects( :save_cache )

    post( '/post', {:text => 'message'}, { 'rack.session' => { :address => thimbl.address, :password => 'pass' } } )
    
    assert( last_response.redirect? )
    assert_match( "/timeline", last_response.location )
  end
  
  def test_follow
    thimbl = Thimbl::Base.new 'me@thimbl.net'
    ThimblSinging::Utils.expects( :charge_thimbl ).with( thimbl.address, true ).returns( thimbl )
    thimbl.expects( 'follow!' ).with( 'nick', 'nick@thimbl.net', 'pass' )
    ThimblSinging::Utils.expects( :save_cache )
    
    post( 
      '/follow',
      {
        :nick     => 'nick', 
        :address  => 'nick@thimbl.net'
      },
      'rack.session' => { :address => thimbl.address, :password => 'pass' }
    )

    assert( last_response.redirect? )
    assert_match( "/timeline", last_response.location )
  end
  
  def test_follow_with_empty_address
    Thimbl::Base.any_instance.expects( 'follow!' ).never
    
    post( 
      '/follow',
      {
        :nick     => '', 
        :address  => ''
      },
      'rack.session' => { :address => 'me@thimbl.net', :password => 'pass' }
    )

    assert( last_response.redirect? )
    assert_match( "/timeline", last_response.location )
  end
  
  def test_unfollow
    thimbl = Thimbl::Base.new 'me@thimbl.net'
    ThimblSinging::Utils.expects( :charge_thimbl ).with( 'me@thimbl.net', true ).returns( thimbl )
    thimbl.expects( 'unfollow!' ).with( 'nick@thimbl.net', 'pass' )
    ThimblSinging::Utils.expects( :save_cache )
    
    post( 
      '/unfollow', 
      { :address  => 'nick@thimbl.net' },
      'rack.session' => { :address => 'me@thimbl.net', :password => 'pass' }
    )

    assert( last_response.redirect? )
    assert_match( "/timeline", last_response.location )
  end
      
  def test_if_not_logged_not_allow_timeline
    get '/timeline', {}, { 'rack.session' => {} }
    assert( last_response.redirect? )
    assert_match( '/', last_response.location )
  end
  
  def test_if_not_logged_not_allow_post
    get '/post', {}, { 'rack.session' => {} }
    assert( last_response.redirect? )
    assert_match( '/', last_response.location )
  end
  
  def test_if_not_logged_not_allow_follow
    get '/follow', {}, { 'rack.session' => {} }
    assert( last_response.redirect? )
    assert_match( '/', last_response.location )
  end
  
  def test_if_not_logged_not_allow_unfollow
    get '/unfollow', {}, { 'rack.session' => {} }
    assert( last_response.redirect? )
    assert_match( '/', last_response.location )
  end
end