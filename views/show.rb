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
      
      def parsed_time
        time = self['time']
        # time = Time.utc( time[0,4], time[4,2], time[6,2], time[8,2], time[10,2], time[12,2] )
        #         return time.strftime '%Y-%m-%d %H:%m'
      end
    end
  end
end
