class ThimblSinging
  module Views
    class Show < Layout
      def messages
        @thimbl.messages.reverse
      end
      
      def me
        @thimbl.me
      end
      
      def last_message
        messages.select { |e| e['address'] == me }.first
      end
      
      def following
        @thimbl.following
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
