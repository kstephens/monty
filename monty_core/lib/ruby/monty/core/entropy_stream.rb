require 'openssl'

module Monty
  module Core
    # Generates pseudo-random stream of Floats or Fixnums from a seed string.
    #
    # Uses RC4 stream cypher on zero bytes to generate 24-bit integers.
    class EntropyStream
      include Monty::Core::Options

      attr_accessor :seed

      def initialize_before_opts
        super
        @seed = nil
      end

      def seed= x
        @seed = x && x.to_s.dup.freeze
        reset!
      end

      def reset!
        @c = nil
      end

      RAW_INT_MAX = (1 << 24)
      RAW_FLT_MAX = RAW_INT_MAX.to_f
      
      def get_float
        get_raw_int.to_f / RAW_FLT_MAX
      end
      alias :to_f :get_float

      def get_raw_int
        return 0 if @seed.nil?
        bytes = _c.update("\0\0\0\0")
        ((bytes[2].to_i) << 16) |
          ((bytes[1].to_i) << 8) |
          (bytes[0].to_i)
      end
      alias :to_i :get_raw_int
      

      CIPHER = 'rc4'.freeze
      NULL_CHAR = "\0".freeze

      def _c
        unless @c 
          c = OpenSSL::Cipher::Cipher.new(CIPHER)
          c.encrypt
          c.key = (seed.to_s + (NULL_CHAR * 128))[0 ... 128]
          @c = c
        end
        @c
      end
      private :_c

    end
  end
end
