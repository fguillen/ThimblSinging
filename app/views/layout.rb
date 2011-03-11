module ThimblSinging
  class App
    module Views
      class Layout < Mustache
        def known_users
          @known_users
        end
      
        def message
          @message
        end
      
        def logged?
          return false  if @session.nil?
          return !@session[:address].nil?
        end
      
        def current_user
          return nil  if @session.nil?
          return ThimblSinging::Utils.charge_thimbl @session[:address]
        end
      
        def user
          @thimbl
        end
      
        def messages
          @thimbl.messages.sort { |a,b| b.time <=> a.time }
        end
      
        def timeline
          @timeline
        end
      
        def last_message
          messages.first
        end
      
        def last_fetch_parsed
          @last_fetch.strftime '%a, %e %b at %H:%M:%S'
        end
      
        # Message helpers
      
        def time_parsed
          self[:time].strftime '%a, %e %b at %H:%M:%S'
        end
      
        # User helpers
      
        def properties_list
          self[:properties].instance_eval('@table').select { |k,v| k != :bio && k != :name }.map{ |k,v| { :key => k, :value => v } }
        end
        
        # CurrentUser helpers
        
        def following?
          current_user.following.count { |e| e.address == self[:address] } != 0
        end
        
        def is_me?
          current_user.address == self[:address]
        end
        
        # Text filters
        
        def activate_links
          lambda do |text|
            ThimblSinging::Utils.activate_all( render( text ) )
          end
        end  
      end
    end
  end
end