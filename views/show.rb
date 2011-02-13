class ThimblSinging
  module Views
    class Show < Mustache
      def messages
        @messages
      end
      
      def me
        @me
      end
      
      def following
        @following
      end
      
      def time_parsed
        time = self['time'].strftime '%a, %e %b at %H:%M:%S'
      end
      
      def last_fetch_parsed
        @last_fetch.strftime '%a, %e %b at %H:%M:%S'
      end
    end
  end
end
