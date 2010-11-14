require 'openssl'

module Monty
  module Core
    # Generates pseudo-random stream of Floats or Fixnums from a seed string.
    #
    # Uses RC4 stream cypher on zero bytes to generate 24-bit integers.
    #
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

      BINARY = "BINARY".freeze
      RAW_INT_MAX = (1 << 24)
      RAW_FLT_MAX = RAW_INT_MAX.to_f
      CIPHER = 'rc4'.freeze
      if RUBY_VERSION >= '1.9'
        NULL_CHAR = "\0".force_encoding(BINARY).freeze
      else
        NULL_CHAR = "\0".freeze
      end
      NULL_4 = (NULL_CHAR * 4).freeze

      # Generates Floats in [0.0, 1.0).
      def get_float
        get_int.to_f / RAW_FLT_MAX
      end
      alias :to_f :get_float

      # Generates Integers in [0.0, RAW_INT_MAX).
      def get_int
        return 0 if @seed.nil?
        bytes = get_4_bytes
        ((bytes[2].to_i) << 16) |
          ((bytes[1].to_i) << 8) |
          (bytes[0].to_i)
      end
      alias :to_i :get_int
      
# Use Ruby 1.9 String#ord
if ?a.class == String
      def get_4_bytes
        _c.update(NULL_4).bytes.to_a
      end
else
      def get_4_bytes
        _c.update(NULL_4)
      end
end

      def _c
        unless @c 
          c = OpenSSL::Cipher::Cipher.new(CIPHER)
          c.encrypt
          key = seed.to_s
          if RUBY_VERSION >= '1.9'
            key = key.dup.force_encoding(BINARY)
          end
          if key.size < 128
            key = (key + (NULL_CHAR * (128 - key.size)))
          end
          if key.size > 128
            key = key[0 ... 128]
          end
          raise Error, 'key size is not 128' if key.size != 128
          # $stderr.puts "key = #{key.inspect}"
          c.key = key
          @c = c
        end
        @c
      end
      private :_c

    end
  end
end
