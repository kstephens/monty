
require 'monty/core/sgml_entity'

module Monty
  module Core
    # Specfies an XSL XPath.
    class XPath
      include Monty::Core::Options

      # The String representation of this XPath.
      attr_accessor :string

      def initialize_before_opts
        super
        @string = nil
        @errors = nil
      end

      def string= x
        @errors = nil
        @string = x
      end

      # Returns true if XPath compiles with xsltproc.
      def valid?
        errors.empty?
      end

      # Return an Array of error Strings.
      def errors
        unless @errors 
          @errors = [ ]
          _validate!
          @errors.freeze
        end
        @errors
      end

      # The escaped XPath as used in a <xsl:template match="..."> attribute.
      def xsl_escape
        @string && SgmlEntity.encode(@string)
      end

      # Generates a validation XSL document.
      def _validation_xsl
        xsl = Xslt.new
        xsl << xsl.header
        xsl << %Q{<xsl:template match="#{self.xsl_escape}" />}
        xsl << xsl.footer
        # $stderr.puts xsl.data
        xsl
      end
      private :_validation_xsl

      # Invokes xsltproc on _validation_xsl.
      # Sets @errors.
      def _validate!
        xsl = _validation_xsl
        xslp = Monty::Core::XslProcessor.new(:xsl => xsl)
        @errors = xslp.validate_xsl() || [ ]
        @errors.reject!{|x| x =~ /^(error$|compilation error: file)/}
        self
      end
      private :_validate!

      alias :to_s :string
    end
  end
end
