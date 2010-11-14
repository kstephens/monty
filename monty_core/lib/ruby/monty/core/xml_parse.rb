
module Monty
  module Core
    # Mixin for _parse_input
    module XmlParse
      # The input parsing mode: :html or :xml
      attr_accessor :document_type

      # Parses input if not already an XML::Document.
      # Selectes parse dependent on @document_type.
      def _parse_input input
        Core.load_libxml!

        case input
        when XML::Document
          return input
        when Array
          input = input * EMPTY_STRING
        when IO
          input = input.read
        end

        case @document_type
        when :html, nil
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
                                     XML::Parser::Options::NOCDATA |
                                     XML::Parser::Options::HUGE |
                                     0)

        input = parser.parse

        if true
          # Look for nasty <!CDATA[ cdata nodes.
          # This is expensive!
          stack = [ input.root ]
          until stack.empty?
            e = stack.pop
            if e.cdata? && 
                (es = e.to_s.dup) && 
                es.sub!(%r{\A\<\!\[CDATA\[}, '') &&
                es.sub!(%r{\]\]\]\]\>\<\!\[CDATA\[\>(.*?)(\]\]\>)}m) { | m | $2 + $1 } 
              # $stderr.puts "#{e.object_id} #{e.type} #{e.path}\n  #{e.to_s.inspect} =>\n   #{es.to_s.inspect}"
              ne = XML::Node.new_text(es)
              ne.output_escaping = false
              e.next = ne
              e.remove!
            end
            stack.push(*e.children)
          end
        end

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
