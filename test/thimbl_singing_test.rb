require "#{File.dirname(__FILE__)}/../thimbl_singing"
require 'rack/test'
require 'test/unit'
require 'webrat'
require 'mocha'

Webrat.configure do |config|
  config.mode = :rack
end

class ThimblSingingTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  def app
    ThimblSinging.new
  end

  def test_root
    visit '/'
    assert_have_selector 'div#activate > form input[name=thimbl_user]'
  end

  def test_show_with_out_parameter
    visit '/show?thimbl_user=me@thimbl.net'
    assert last_response.redirect?
    assert_match "/me@thimbl.net", last_response.location
  end

  def test_show
    thimbl = Thimbl::Base.new
    thimbl.data = JSON.load File.read "#{File.dirname(__FILE__)}/fixtures/me_at_thimbl.net.json"
    ThimblSinging.expects( :charge_thimbl ).with( 'me@thimbl.net' ).returns( thimbl )
    File.stubs( :mtime ).returns( Time.utc 2010, 1, 2, 3, 4, 5 )
    visit '/me@thimbl.net'
    
    # File.open( '/tmp/exit.html', 'w' ) { |f| f.write response.body }
    
    # activate form
    assert_have_selector 'div#activate > form input[name=thimbl_user]'
    
    # title
    # assert_have_selector 'h1', :content => 'me@thimbl.net'
    
    # last update data
    assert_contain 'updated last time in Sat, 2 Jan at 03:04'
    
    # post form
    assert_have_selector 'div#post > form textarea[name=text]'
    
    # last message
    assert_have_selector 'div#last-message', :content => 'testing 3'
    
    # messages
    assert_have_selector 'div#messages > .message > .time', :content => 'Wed,  2 Feb at 15:23:39'
    assert_have_selector 'div#messages > .message > .address > a', :content => 'dk@telekommunisten.org'
    assert_have_selector 'div#messages > .message > .text', :content => 'Hello from the thimbl workshop'
    assert_contain 'Hello from the thimbl workshop by dk@telekommunisten.org at Wed, 2 Feb at 15:23:39'
    
    # followings
    assert_have_selector 'div#followings > .following > .nick', :content => 'dk'
    assert_have_selector 'div#followings > .following > .address', :content => 'dk@telekommunisten.org'
    
    # add following form
    assert_have_selector 'div#followings > div#add-following > form input[name=nick]'
  end
  
  def test_show_json
    data = { 'a' => 1 }
    thimbl = Thimbl::Base.new
    ThimblSinging.expects( :charge_thimbl ).with( 'me@thimbl.net' ).returns( thimbl )
    thimbl.stubs( :plan ).returns( data )
    
    get '/me@thimbl.net.json'
    
    assert_equal 'application/json', last_response.content_type
    assert_equal( data, JSON.load( last_response.body ) )
  end
  
  def test_fetch
    Thimbl::Base.any_instance.expects( :fetch ).twice
    ThimblSinging.expects( :save_cache )
    
    get '/me@thimbl.net/fetch'
    
    assert last_response.redirect?
    assert_match "/me@thimbl.net", last_response.location
  end
  
  def test_post
    thimbl = Thimbl::Base.new
    ThimblSinging.expects( :charge_thimbl ).with( 'me@thimbl.net' ).returns( thimbl )
    Thimbl::Base.any_instance.expects( 'post!' ).with( 'message', 'pass' )
    ThimblSinging.expects( :save_cache )

    post( '/me@thimbl.net/post', :text => 'message', :password => 'pass' )
    
    assert last_response.redirect?
    assert_match "/me@thimbl.net", last_response.location
  end
  
  def test_follow
    thimbl = Thimbl::Base.new
    ThimblSinging.expects( :charge_thimbl ).with( 'me@thimbl.net' ).returns( thimbl )
    Thimbl::Base.any_instance.expects( 'follow!' ).with( 'nick', 'nick@thimbl.net', 'pass' )
    Thimbl::Base.any_instance.expects( :fetch )
    ThimblSinging.expects( :save_cache )

    post( '/me@thimbl.net/follow', :nick => 'nick', :address => 'nick@thimbl.net', :password => 'pass' )
    
    assert last_response.redirect?
    assert_match "/me@thimbl.net", last_response.location
  end
  
  def test_to_filename
    assert_equal( 'pepe_at_thimbl.net', ThimblSinging.to_filename( 'pepe@thimbl.net' ) )
  end
  
  def test_save_cache
    caches_path = "#{Dir.tmpdir}/caches"
    ThimblSinging.stubs( :caches_path ).returns caches_path
    
    ThimblSinging.save_cache( 'me@thimbl.net', 'data' )
    
    assert_equal( '"data"', File.read( "#{caches_path}/me_at_thimbl.net.json" ) )
  end
  
  def test_load_cache
    caches_path = "#{Dir.tmpdir}/caches"
    data = { 'a' => 1 }
    ThimblSinging.stubs( :caches_path ).returns caches_path

    FileUtils.mkdir_p caches_path
    File.open( "#{caches_path}/me_at_thimbl.net.json", 'w' ) do |f|
      f.write data.to_json
    end
    
    assert_equal( data, ThimblSinging.load_cache( 'me@thimbl.net' ) )
  end
  
  def test_load_cache_not_existing
    assert_equal( nil, ThimblSinging.load_cache( 'not_exists@thimbl.net' ) )
  end
  
  def test_charge_thimbl
    ThimblSinging.expects( :load_cache ).returns( 'website' => 'wadus.com' )
    Thimbl::Base.any_instance.expects( 'data=' )
    Thimbl::Base.any_instance.expects( :fetch ).never
    ThimblSinging.expects( :save_cache ).never
    ThimblSinging.charge_thimbl 'me@thimbl.net'
  end
  
  def test_charge_thimbl_not_existing_yet
    ThimblSinging.expects( :load_cache ).returns( nil )
    Thimbl::Base.any_instance.expects( 'data=' ).never
    Thimbl::Base.any_instance.expects( :fetch ).twice
    ThimblSinging.expects( :save_cache )
    ThimblSinging.charge_thimbl 'me@thimbl.net'
  end
  
  def test_know_users
    caches_path = "#{File.dirname(__FILE__)}/fixtures/known_users_caches"
    ThimblSinging.stubs( :caches_path ).returns caches_path
    File.expects( :mtime ).with( "#{File.dirname(__FILE__)}/fixtures/known_users_caches/one_at_thimbl.net.json" ).returns( Time.utc 2010, 1, 2, 3, 4, 5 )
    File.expects( :mtime ).with( "#{File.dirname(__FILE__)}/fixtures/known_users_caches/two_at_thimbl.net.json" ).returns( Time.utc 2010, 1, 2, 3, 4, 6 )

    known_users = ThimblSinging.known_users

    assert_equal 'one@thimbl.net', known_users.first['address']
    assert_equal '20100102030405', known_users.first['last_fetch'].strftime('%Y%m%d%H%M%S')
    assert_equal 'two@thimbl.net', known_users.last['address']
    assert_equal '20100102030406', known_users.last['last_fetch'].strftime('%Y%m%d%H%M%S')
  end
end