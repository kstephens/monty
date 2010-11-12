module Monty
  module Core
    # Matches a URI string.
    #
    # "*" matches zero or more non-'/' characters
    # "*" matches zero or more characters.
    # "c?" matches "c" zero or one times.
    # All other sequences match literally.
    class UriPattern
      include Monty::Core::Options

      # A String that lists patterns that alternatively match a URI.
      # Each pattern is separated by /\s+|\s*,\s*/.
      attr_accessor :string

      # An Array of Strings that alternatively match a URI.
      attr_accessor :patterns

      def initialize_before_opts
        super
        @string = nil
        @patterns = nil
      end

      def patterns
        @patterns ||=
          (@string || '').split(/\s+|\s*,\s*/)
      end
      def patterns= x
        @patterns = x || EMPTY_ARRAY
        @string = @rx = nil
      end

      def string 
        @string ||=
          (@pattern || EMPTY_ARRAY).join(", ")
      end
      def string= x
        @string = x
        @patterns = @rx = nil
      end

      # Returns a Regexp that matches the URI String.
      def to_rx
        @rx ||=
          (x = patterns).empty? ? REGEXP_ANY :
          Regexp.new("\\A(?:" + (x.map{|p| _pat_to_rx(p)} * '|') + ")\\Z") 
        # $stderr.puts "rx = #{@rx.inspect}"; @rx
      end

      REGEXP_ANY = //;

      def _pat_to_rx p
        p = p.dup
        p.gsub!(/\./, "\001")
        p.gsub!(/\*\*/, "\002")
        p.gsub!(/\*/, "\003")
        p.gsub!("\003", "[^/]*")
        p.gsub!("\002", ".*")
        p.gsub!("\001", "\\.")
        p
      end
      
      def === str
        to_rx === str.to_s
      end

      def match str
        to_rx.match(str.to_s)
      end
    end
  end
end
