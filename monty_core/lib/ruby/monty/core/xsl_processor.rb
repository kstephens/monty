require 'monty/core/sgml_entity'
require 'monty/core/xml_parse'

module Monty
  module Core
    # Interface to XSL Processor.
    class XslProcessor
      include Monty::Core::Options
      include Monty::Core::XmlParse

      # The Xsl object.
      attr_accessor :xsl
      
      # The SGML DOCTYPE: :xhtml_transitional, :xhtml_strict
      attr_accessor :sgml_doctype

      # If true, enabled debugging.
      attr_accessor :debug

      # If true, use xsltproc binary, instead of libxslt.
      attr_accessor :use_xsltproc

      # Argument String for xsltproc.
      attr_accessor :xsltproc_args

      def initialize_before_opts
        super
        @document_type = :html
        @sgml_doctype = :xhtml_transitional
        @debug = false
      end

      # input may be a String or an XML::Document.
      # params is a Hash.
      # output can be any object that responds to #<<(String).
      def apply(input, params = nil, output = nil)
        output ||= ''
        params ||= EMPTY_HASH

        if xsl.identity?
          # $stderr.puts "identity"
          output << input
        else
          output << _process(input, params)
        end

        output
      end
      
      SGML_DOCTYPES = {
        :xhtml_transitional =>
        %Q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">}.freeze,
        :xhtml_strict => 
        %Q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">}.freeze,
      }

      def validate_xsl params = nil
        params ||= EMPTY_HASH
        self.xsl_file = "/tmp/monty-#{$$}.xsl"
        self.xml_file = "/tmp/monty-#{$$}.xml"
        save_xsltproc_args = @xsltproc_args
        @xsltproc_args = '--noout'
        File.open(self.xsl_file, "w+") do | fh |
          fh.write xsl.data
        end
        File.open(self.xml_file, "w+") do | fh |
          fh.write <<'END'
<?xml version="1.0" encoding="utf-8"?>
<dummy>
</dummy>
END
        end
        xsltproc params
        @errors = @xsltproc_stderr.split("\n")
        @errors = nil if @errors.empty?
        @xstproc_stderr = @xsltproc_stdout = nil
        @errors
      ensure 
        @xsltproc_args = save_xsltproc_args
        File.unlink(self.xsl_file) rescue nil
        File.unlink(self.xml_file) rescue nil
      end

      attr_accessor :xsl_file, :xml_file
      def _process(input, params)
        if @use_xsltproc
          # $stderr.puts gen.output.string
          File.open(self.xsl_file ||= "/tmp/monty.xsl", "w+") do | fh |
            fh.write xsl.data
          end
          File.open(self.xml_file ||= "/tmp/in.xml", "w+") do | fh |
            fh.write input
          end
          result = xsltproc
        else
          # STDERR.puts "input =\n#{input}"
          return input if input == EMPTY_STRING

          # Parse the DOM from the input stream.
          input = _parse_input(input)

          # Apply the XSL to the input w/ the parameters.
          result_dom = xsl.stylesheet.apply(input, params)

          # STDERR.puts "result_dom = #{result_dom.inspect}" if @debug
          if Exception === result_dom
            raise Monty::Core::Error, "#{self.class.name} #{result_dom.inspect}"
          end

          # Get the XML DOM data as a String.
          result_dom = result_dom.root.to_s
          
          # Remove the html xmlns.
          result_dom.sub!(/^<html xmlns=[^>]+>/, '<html>')

          # Browsers cannot handle self-terminated block-oriented tags: <script .../> and <div .../>.
          result_dom.gsub!(%r{<((script|div)[^>]*?)/>}mi) { | x | '<' + $1 + '></' + $2 + '>'}

          # Unescaping SGML entities in block-oriented tags: <script> and <style> tags.
          result_dom.gsub!(%r{(<(script|style)[^>]*?>)(.+?)(</\2>)}mi) do | x |
            tag_start, content, tag_end = $1, $3, $4
            # STDERR.puts " =====> #{tag_start} #{content} #{tag_end}"
            SgmlEntity.decode!(content)
            tag_start << content << tag_end
          end

          # Add the appropriate SGML <!DOCTYPE ...> tag.
          result = (SGML_DOCTYPES[sgml_doctype] || sgml_doctype).to_s.dup << "\n"

          # Append the modified XML DOM data.
          result << result_dom
        end

        result
      end
      private :_process


      def xsltproc params = nil
        require "open3"

        params ||= EMPTY_HASH
        args = (@xsltproc_args || '').dup
        params.each do | k, v |
          args << " --param #{k} #{v.inspect}"
        end

        cmd = "xsltproc #{args} #{self.xsl_file} #{self.xml_file}"

        @xsltproc_stdout = ''
        @xsltproc_stdin = ''
        Open3.popen3(cmd) do |stdin, stdout, stderr|
          stdin.close
          @xsltproc_stdout = stdout.read
          @xsltproc_stderr = stderr.read
        end
        @xsltproc_stdout
      end

=begin
      SGML_ENTITY_MAP = { 
        '&lt;' => '<', 
        '&gt;' => '>', 
        '&amp;' => '&',
      }.freeze.each { | k, v | k.freeze; v.freeze }
=end

     private :_parse_input

    end # class
  end # module
end # module

