require "#{File.dirname(__FILE__)}/test_helper"

class UtilsTest < Test::Unit::TestCase    
  def test_save_cache
    caches_path = "#{Dir.tmpdir}/caches"
    ThimblSinging::Utils.stubs( :caches_path ).returns( caches_path )
    
    ThimblSinging::Utils.save_cache( 'me@thimbl.net', 'data' )
    
    assert_equal( '"data"', File.read( "#{caches_path}/me@thimbl.net.json" ) )
  end
  
  def test_load_cache
    caches_path = "#{Dir.tmpdir}/caches"
    data = { 'a' => 1 }
    ThimblSinging::Utils.stubs( :caches_path ).returns( caches_path )

    FileUtils.mkdir_p( caches_path )
    File.open( "#{caches_path}/me@thimbl.net.json", 'w' ) do |f|
      f.write( data.to_json )
    end
    
    assert_equal( data, ThimblSinging::Utils.load_cache( 'me@thimbl.net' ) )
  end
  
  def test_load_cache_not_existing
    assert_equal( nil, ThimblSinging::Utils.load_cache( 'not_exists@thimbl.net' ) )
  end
  
  def test_charge_thimbl
    data = {:key => 'value'}
    ThimblSinging::Utils.expects( :load_cache ).returns( data )
    Thimbl::Base.any_instance.expects( 'data=' ).with( data )
    Thimbl::Base.any_instance.expects( :fetch ).never
    ThimblSinging::Utils.expects( :save_cache ).never
    
    ThimblSinging::Utils.charge_thimbl 'me@thimbl.net'
  end
  
  def test_charge_thimbl_not_existing_yet
    ThimblSinging::Utils.expects( :load_cache ).returns( nil )
    Thimbl::Base.any_instance.expects( :fetch )
    ThimblSinging::Utils.expects( :save_cache )
    
    ThimblSinging::Utils.charge_thimbl( 'me@thimbl.net' )
  end
  
  def test_charge_thimbl_existing_but_force_update
    data = { :key => 'value' }
    ThimblSinging::Utils.expects( :load_cache ).returns( data )
    Thimbl::Base.any_instance.expects( 'data=' ).with( data )
    Thimbl::Base.any_instance.expects( :fetch )
    ThimblSinging::Utils.expects( :save_cache )
    
    ThimblSinging::Utils.charge_thimbl( 'me@thimbl.net', true )
  end
  
  def test_charge_timeline
    Thimbl::Base.any_instance.expects( :fetch ).never
    ThimblSinging::Utils.stubs( :caches_path ).returns( "#{FIXTURES_PATH}/caches" )
    
    messages = ThimblSinging::Utils.charge_timeline( 'me@thimbl.net' )

    assert_equal( 6, messages.size )
    assert_equal( 'one@thimbl.net', messages.first.address )
    assert_equal( 'user a message 1', messages.first.text )
    assert_equal( '20101105124412', messages.first.time.strftime('%Y%m%d%H%M%S') )
    assert_equal( 'me@thimbl.net', messages.last.address )
    assert_equal( 'message 2', messages.last.text )
    assert_equal( '20100706125120', messages.last.time.strftime('%Y%m%d%H%M%S') )
  end
  
  def test_charge_timeline_force_update
    Thimbl::Base.any_instance.expects( :fetch ).times( 3 )
    ThimblSinging::Utils.stubs( :save_cache ).times( 3 )
    ThimblSinging::Utils.stubs( :caches_path ).returns( "#{FIXTURES_PATH}/caches" )
    
    ThimblSinging::Utils.charge_timeline( 'me@thimbl.net', true )
  end
  
  def test_global_time_line
    Thimbl::Base.any_instance.expects( :fetch ).never
    ThimblSinging::Utils.stubs( :caches_path ).returns( "#{FIXTURES_PATH}/caches" )
    
    messages = ThimblSinging::Utils.charge_global_timeline

    assert_equal( 6, messages.size )
    assert_equal( 'one@thimbl.net', messages.first.address )
    assert_equal( 'user a message 1', messages.first.text )
    assert_equal( '20101105124412', messages.first.time.strftime('%Y%m%d%H%M%S') )
    assert_equal( 'me@thimbl.net', messages.last.address )
    assert_equal( 'message 2', messages.last.text )
    assert_equal( '20100706125120', messages.last.time.strftime('%Y%m%d%H%M%S') )
  end
  
  def test_charge_global_timeline_force_update
    Thimbl::Base.any_instance.expects( :fetch ).times( 3 )
    ThimblSinging::Utils.stubs( :save_cache ).times( 3 )
    ThimblSinging::Utils.stubs( :caches_path ).returns( "#{FIXTURES_PATH}/caches" )
    
    ThimblSinging::Utils.charge_global_timeline( true )
  end
  
  def test_charge_thimbls
    ThimblSinging::Utils.expects( :charge_thimbl ).with( :a, true ).returns( 'a' )
    ThimblSinging::Utils.expects( :charge_thimbl ).with( :b, true ).returns( 'b' )
    ThimblSinging::Utils.expects( :charge_thimbl ).with( :c, true ).returns( 'c' )
    
    thimbls = ThimblSinging::Utils.charge_thimbls( [:a, :b, :c], true )
    
    assert_equal( ['a', 'b', 'c'], thimbls )
  end
  
  def test_last_global_fetch
    ThimblSinging::Utils.stubs( :caches_path ).returns( "#{FIXTURES_PATH}/caches" )
    File.expects( :mtime ).with( "#{FIXTURES_PATH}/caches/me@thimbl.net.json" ).returns( Time.parse( '2010-01-01 10:20:30' ) )
    assert_equal( Time.parse( '2010-01-01 10:20:30' ), ThimblSinging::Utils.last_global_fetch )
  end
  
  def test_last_global_fetch_when_not_any_cache
    caches_path = "#{Dir.tmpdir}/empty_caches"
    FileUtils.mkdir_p( caches_path )
    
    ThimblSinging::Utils.stubs( :caches_path ).returns( caches_path )
    
    File.expects( :mtime ).never
    assert_equal( Time.parse( '2010-01-01 00:00:00' ), ThimblSinging::Utils.last_global_fetch )
  end
  
  
  def test_known_users
    caches_path = "#{File.dirname(__FILE__)}/fixtures/caches"
    ThimblSinging::Utils.stubs( :caches_path ).returns( caches_path )

    known_users = ThimblSinging::Utils.known_users

    assert_equal( 'me@thimbl.net', known_users.first.address )
    assert_equal( 'User Name', known_users.first.properties.name )
    assert_equal( 'two@thimbl.net', known_users.last.address )
    assert_equal( 'User B Name', known_users.last.properties.name )
  end
  
  def test_activate_links
    fixtures = [
      [
        'text with link.com and more text.',
        'text with <a href="http://link.com">link.com</a> and more text.',
      ],
      [
        'text with link.com/Image.jpg and more text.',
        'text with <a href="http://link.com/Image.jpg">link.com/Image.jpg</a> and more text.',
      ],
      [
        'text with http://link.com and more text.',
        'text with <a href="http://link.com">http://link.com</a> and more text.'
      ],
      [
        'text with link.com and another.link.com.',
        'text with <a href="http://link.com">link.com</a> and <a href="http://another.link.com.">another.link.com.</a>'
      ],
      [
        'transmediale was fun, Thimbl got a distinction and moves onwards...',
        'transmediale was fun, Thimbl got a distinction and moves onwards...'
      ]
    ]

    fixtures.each do |original, result|
      assert_equal( result, ThimblSinging::Utils.activate_links( original ) )
    end
  end
  
  # TODO: works enough well for prototiping
  def test_activate_addresses
    fixtures = [
      [
        'text with address@thimbl.com.tk and more text.',
        'text with <a href="/address@thimbl.com.tk">address@thimbl.com.tk</a> and more text.',
      ]
    ]

    fixtures.each do |original, result|
      assert_equal( result, ThimblSinging::Utils.activate_addresses( original ) )
    end
  end
  
  # def test_activate_all
  #   fixtures =[
  #     [
  #       'text with address@thimbl.com.tk with a link.com and a link.com/user@thimbl.net and more text.',
  #       'text with <a href="/address@thimbl.com.tk">address@thimbl.com.tk</a> with a <a href="http://link.com">link.com</a> and a link.com/<a href="/user@thimbl.net">user@thimbl.net</a> and more text.',
  #     ],
  #     [
  #       'Renee Turner Live Thimbling from Piet Zwart : http://singing.thimbl.net/rgeuzen@pzi.thimbl.net',
  #       'Renee Turner Live Thimbling from Piet Zwart : http://singing.thimbl.net/<a href="/rgeuzen@pzi.thimbl.net">rgeuzen@pzi.thimbl.net</a>',
  #     ]
  #   ]
  # 
  #   fixtures.each do |original, result|
  #     assert_equal( result, ThimblSinging::Utils.activate_all( original ) )
  #   end
  # end
end