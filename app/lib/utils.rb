module ThimblSinging
  class Utils
    def self.charge_thimbl( address, force_update = false )
      thimbl = Thimbl::Base.new( address )
      thimbl.data = ThimblSinging::Utils.load_cache( address )

      if( force_update || thimbl.data.nil? )
        thimbl.fetch
        ThimblSinging::Utils.save_cache( thimbl.address, thimbl.data )
      end

      return thimbl
    end

    def self.charge_timeline( address, force_update = false )
      thimbl = ThimblSinging::Utils.charge_thimbl( address, force_update )
      followed = ThimblSinging::Utils.charge_thimbls( thimbl.following.map( &:address ), force_update )
      
      messages = thimbl.messages + followed.map( &:messages ).flatten
      messages = messages.sort { |a,b| b.time <=> a.time }
      
      return messages
    end

    def self.charge_global_timeline( force_update = false )
      thimbls = ThimblSinging::Utils.charge_thimbls( ThimblSinging::Utils.known_users.map( &:address ), force_update )
      
      messages = thimbls.map( &:messages ).flatten
      messages = messages.sort { |a,b| b.time <=> a.time }
      
      return messages
    end

    def self.charge_thimbls( addresses, force_update = false )
      result = []

      addresses.each do |address|
        begin
          result << ThimblSinging::Utils.charge_thimbl( address, force_update )
        rescue Thimbl::NoPlanException
          puts "Error fingering: '#{address}'"
        end
      end

      return result
    end

    def self.load_cache( address )
      cache_path = "#{ThimblSinging::Utils.caches_path}/#{address}.json"
      return nil  unless File.exists?( cache_path )
      return JSON.load( File.read( cache_path ) )
    end

    def self.save_cache( address, data )
      FileUtils.mkdir( ThimblSinging::Utils.caches_path )  unless File.exists?( ThimblSinging::Utils.caches_path )
      cache_path = "#{ThimblSinging::Utils.caches_path}/#{address}.json"
      File.open( cache_path, 'w' ) { |f| f.write data.to_json }
    end

    def self.last_fetch( address )
      File.mtime "#{ThimblSinging::Utils.caches_path}/#{address}.json"
    end

    # TODO: figure out another more inteligent way to know when was the last global_update
    def self.last_global_fetch
      cache_path = Dir["#{ThimblSinging::Utils.caches_path}/*.json"].first
            
      return Time.parse( '2010-01-01' )  if cache_path.nil?
      
      File.mtime( cache_path )
    end

    def self.known_users
      result = []

      Dir["#{ThimblSinging::Utils.caches_path}/*.json"].each do |cache_path|
        address = File.basename( cache_path, '.json' )
        thimbl = ThimblSinging::Utils.charge_thimbl( address )
        result << thimbl
      end

      return result
    end

    def self.caches_path
      File.expand_path( "#{File.dirname(__FILE__)}/../../caches" )
    end

    # TODO: don't take the last dot in: 'link.com.'
    URL_REGEX = /((((http|https):\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}([^\s,<">]*)?))/xi   
    ADDRESS_REGEX = /([\w\!\#$\%\&\'\*\+\-\/\=\?\^\`{\|\}\~]+\.)*[\w-]+@((((([a-z0-9]{1}[a-z0-9\-]{0,62}[a-z0-9]{1})|[a-z])\.)+[a-z]{2,6})|(\d{1,3}\.){3}\d{1,3}(\:\d{1,5})?)/i
    
    def self.activate_links( text )
      text.gsub!( URL_REGEX ) do |url|
        clean_url = url.gsub( /http:\/\//i, '' )
        "<a href=\"http://#{clean_url}\">#{url}</a>"
       end
  
      return text
    end
    
    def self.activate_addresses( text )
      text.gsub!( ADDRESS_REGEX ) do |address|
        "<a href=\"/#{address}\">#{address}</a>"
      end
  
      return text
    end

    
    def self.activate_all( text )
      text = ThimblSinging::Utils.activate_links( text )
      # text = ThimblSinging::Utils.activate_addresses( text ) # Not ready yet
      
      return text
    end
    
  end
end