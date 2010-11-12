gem 'libxslt-ruby'
require 'xslt'

module Monty
  module Core
    # Mixin for _parse_input
    module XmlParse
      # The input parsing mode: :html or :xml
      attr_accessor :document_type

      # Parses input if not already an XML::Document.
      # Selectes parse dependent on @document_type.
      def _parse_input input
        return input if XML::Document === input

        case @document_type
        when :html
          parser_class = XML::HTMLParser
        when :xml
          parser_class = XML::Parser
        else
          raise ArgumentError, "@document_type: expected :html or :xml"
        end

        # $stderr.puts "input = #{input.inspect}"

        parser = parser_class.string(input,
                                     :options =>
                                     XML::Parser::Options::RECOVER |
                                     XML::Parser::Options::NONET |
                                     XML::Parser::Options::PEDANTIC |
                                     0)

        input = parser.parse

=begin
        divs = input.find('//div')
        $stderr.puts "  ### divs = #{divs.class}"
        divs.each do | e | 
          $stderr.puts "  ### e = #{e.class} #{e.path}"
        end
=end

        input
      end
    end
  end
end
