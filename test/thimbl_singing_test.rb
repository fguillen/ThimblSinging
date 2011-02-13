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
    assert_match "/me@thimbl.net/show", last_response.location
  end

  def test_show
    thimbl = Thimbl::Base.new
    thimbl.data = JSON.load File.read "#{File.dirname(__FILE__)}/fixtures/me_at_thimbl.net.json"
    ThimblSinging.expects( :charge_thimbl ).with( 'me@thimbl.net' ).returns( thimbl )
    File.expects( :atime ).returns( Time.utc 2010, 1, 2, 3, 4, 5 )
    visit '/me@thimbl.net/show'
    
    # activate form
    assert_have_selector 'div#activate > form input[name=thimbl_user]'
    
    # title
    assert_have_selector 'h1', :content => 'me@thimbl.net'
    
    # last update data
    assert_contain 'updated last time in Sat, 2 Jan at 03:04:05'
    
    # post form
    assert_have_selector 'div#post > form textarea[name=text]'
    
    # messages
    assert_have_selector 'div#messages > .message > .time', :content => 'Wed,  2 Feb at 15:23:39'
    assert_have_selector 'div#messages > .message > .address', :content => 'dk@telekommunisten.org'
    assert_have_selector 'div#messages > .message > .text', :content => 'Hello from the thimbl workshop'
    assert_contain 'On Wed, 2 Feb at 15:23:39 dk@telekommunisten.org said Hello from the thimbl workshop'
    
    # followings
    assert_have_selector 'div#followings > .following > .nick', :content => 'dk'
    assert_have_selector 'div#followings > .following > .address', :content => 'dk@telekommunisten.org'
    
    # add following form
    assert_have_selector 'div#followings > div#add-following > form input[name=nick]'
  end
  
  def test_fetch
    Thimbl::Base.any_instance.expects( :fetch ).twice
    ThimblSinging.expects( :save_cache )
    
    get '/me@thimbl.net/fetch'
    
    assert last_response.redirect?
    assert_match "/me@thimbl.net/show", last_response.location
  end
  
  def test_post
    thimbl = Thimbl::Base.new
    ThimblSinging.expects( :charge_thimbl ).with( 'me@thimbl.net' ).returns( thimbl )
    Thimbl::Base.any_instance.expects( 'post!' ).with( 'message', 'pass' )
    ThimblSinging.expects( :save_cache )

    post( '/me@thimbl.net/post', :text => 'message', :password => 'pass' )
    
    assert last_response.redirect?
    assert_match "/me@thimbl.net/show", last_response.location
  end
  
  def test_follow
    thimbl = Thimbl::Base.new
    ThimblSinging.expects( :charge_thimbl ).with( 'me@thimbl.net' ).returns( thimbl )
    Thimbl::Base.any_instance.expects( 'follow!' ).with( 'nick', 'nick@thimbl.net', 'pass' )
    Thimbl::Base.any_instance.expects( :fetch )
    ThimblSinging.expects( :save_cache )

    post( '/me@thimbl.net/follow', :nick => 'nick', :address => 'nick@thimbl.net', :password => 'pass' )
    
    assert last_response.redirect?
    assert_match "/me@thimbl.net/show", last_response.location
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
end