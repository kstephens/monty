module Monty
  module Core
    module SgmlEntity
      SGML_ENTITY_DECODE_MAP = { 
        '&lt;' => '<', 
        '&gt;' => '>', 
        '&amp;' => '&',
        '&apos;' => "'",
        '&quot;' => '"',
      }.freeze.each { | k, v | k.freeze; v.freeze }

      SGML_ENTITY_DECODE_RX = /#{SGML_ENTITY_DECODE_MAP.keys * "|"}/

      SGML_ENTITY_ENCODE_MAP = { }
      SGML_ENTITY_DECODE_MAP.each { | k, v | SGML_ENTITY_ENCODE_MAP[v] = k }
      SGML_ENTITY_ENCODE_MAP.freeze

      SGML_ENTITY_ENCODE_RX = /#{SGML_ENTITY_DECODE_MAP.keys * "|"}/

      def encode! str
        str.gsub!(SGML_ENTITY_ENCODE_RX) { | x | SGML_ENTITY_ENCODE_MAP[x] || x }
        str
      end

      def encode str
        encode!(str.dup)
      end

      def decode! str
        str.gsub!(SGML_ENTITY_DECODE_RX) { | x | SGML_ENTITY_DECODE_MAP[x] || x }
        str
      end

      def decode str
        decode!(str.dup)
      end

      extend self
    end # module
  end # module
end # module


