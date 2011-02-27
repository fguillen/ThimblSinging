class ThimblSinging
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
        return !@session[:user].nil?
      end
      
      def user
        return false  if @session.nil?
        return @session[:user]
      end
    end
  end
end
