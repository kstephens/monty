module Monty
  module Core
    # Generates an XSL from an Experiment or ExperimentSet.
    #
    # FIXME: Rename XslGenerator.
    class XsltGenerator
      include Monty::Core::Options

      # The input document and state to transform.

      # The output XSL document.
      attr_accessor :output

      attr_accessor :is_identity

      # If true, enable debugging in the XSL.
      attr_accessor :debug

      def initialize_before_opts
        super
        @is_identity = nil
        @debug = false

        @param_index = 0
        @output ||= $stdout
      end

      def out str
        @output.write str.to_s
      end

      def outln str
        @output.write str.to_s
        @output.write NEWLINE
      end


      # Called with a ExperimentSet to generate the appropriate XSLT.
      def generate obj
        _generate_header
        _generate obj
        _generate_footer
      end


      ####################################################################################

      @@method_cache = { }

      def _generate obj, *args
        meth = @@method_cache[obj.class.name] ||=
          obj.class.ancestors.map{|m| '_generate_' << m.name.sub(/.*::/, '')}.
          find{|m| respond_to?(m)}.
          freeze

        case obj
        when String, Symbol, Numeric, Hash, Array
          comment = false
        when
          comment = args.size <= 1
        end

        indent_save = (@indent ||= '')

        if comment
          out <<"END" 
#{@indent}<!-- #{obj.class.name} id="#{obj.id}" -->
END
          @indent += '  '
        end

        send(meth, obj, *args)

        if comment
          out <<"END" 
#{@indent}<!-- /#{obj.class.name} id="#{obj.id}" -->
END
          @indent = indent_save
        end
        
        self
      end

      ####################################################################################

      def _generate_header
        out <<'END'
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exslt="http://exslt.org/common">

<!--
This causes problems with Ruby libxslt.

  <xsl:output method="html"
    doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd" />
-->

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="comment() | processing-instruction()">
    <xsl:copy>.</xsl:copy>
  </xsl:template>

<!-- header END -->

END
      end

      def _generate_footer
        out <<'END'

<!-- footer -->
</xsl:stylesheet>
END
      end


      def is_identity= x
        @is_identity = x
        @out.identity = x if @out.respond_to?(:identity=)
        # $stderr.puts "is_identity = #{x.inspect}" if x == false
        self
      end

      def _generate_ExperimentSet obj
        self.is_identity = true if @is_identity.nil?
        obj.applicable_experiments(input).each do | c |
          _generate c
        end
      end

      def _generate_Experiment obj
        self.is_identity = true if @is_identity.nil?
        out <<"END"
  <!-- name   #{obj.name} -->
END

        experiment_save = @experiment
        @experiment = obj

        # Generate a parameter name.
        @param_index += 1
        param_name = "param_#{@param_index}"
        output.add_parameter!(param_name) if output.respond_to?(:add_parameter!)
        param_name = "$#{param_name}"
        @param_name = param_name

        # Save some metadata in the output XSL.
        opts = {
          :experiment => obj,
          :param_name => param_name,
        }
        output.optional_data = opts if output.respond_to?(:optional_data=)

        # Get the list of ordered possibilities.
        objs = obj.possibilities_ordered
        
        # Compute the sum of all Possibility weights.
        obj.compute_weight_ranges!

        # require 'pp'; pp opts, $stderr

        obj.possibilities.each do | p |
          _generate p, opts
        end

        obj.rules.each do | r |
          _generate_rule r, opts
        end
      ensure
        @experiment = experiment_save
      end


      def _generate_Possibility obj, opts
        out <<"END"
    <!-- name   #{obj.name} -->
    <!-- weight #{obj.weight} -->
END
  
      end


      ################################################################
      # Rule
      #


      def _generate_rule rule, opts
        if rule.respond_to?(:path_other)
          _generate rule, opts, :all
        else
          _generate_template rule.path, rule, opts do | mode |
            _generate rule, opts, mode
          end
        end
      end


      def _generate_template path, rule, opts
        out <<"END"

  <!-- Rule #{rule.name}: #{rule.to_s} -->
  <xsl:template match="#{encode_path(path)}">
END
        yield :header

        outln '    <xsl:choose>'

        out <<"END"
      <!-- Default -->
      <xsl:when test="number(#{opts[:param_name]}) &lt; number(0.0) or number(#{opts[:param_name]}) &gt;= number(1.0)">
END

        yield false

        out <<"END"
      </xsl:when>
END

        @experiment.possibilities.each do | pos |
          offset = pos.probability_range.last
          enabled = ! ! @experiment[pos, rule]
          out <<"END"
      <!-- Possibility #{pos.name} => #{enabled.inspect} -->
      <xsl:when test="number(#{opts[:param_name]}) &lt; number(#{offset})">
END
          out <<"END" if @debug
        <xsl:comment> Possibility #{pos.name}, Rule #{rule.name}, #{enabled.inspect} </xsl:comment>
END

          yield enabled

          out <<"END"
      </xsl:when>
END
        end
        
        outln '    </xsl:choose>'

        yield :footer
        
        out <<"END"
  </xsl:template>
END
      end

      def _generate_ChangeAttribute rule, opts, mode
        case mode
        when true
          self.is_identity = false
          out <<"END"
        <xsl:copy>
          <xsl:copy-of select="@*[not(name()='#{rule.attribute_name}')]" />
          <xsl:attribute name="#{rule.attribute_name}">#{rule.attribute_value}</xsl:attribute>
          <xsl:apply-templates select="./node()" />
        </xsl:copy>
END
        when false
          outln '        <xsl:copy-of select="." />'
        end
      end

      def _generate_ChangeContent rule, opts, mode
        case mode
        when true
          self.is_identity = false
          data = rule.content
          data = data.data unless String === data
          out <<"END"
        <xsl:copy><xsl:copy-of select="@*" />#{data}</xsl:copy>
END
        when false
          outln '        <xsl:copy-of select="." />'
        end
      end

      # See http://social.msdn.microsoft.com/Forums/en-SG/msxml/thread/0048f29d-9c9c-4f64-9791-aadbb4fd4711
      def _generate_SwapContent rule, opts, mode
        _generate_template rule.path, rule, opts do | mode |
          case mode
          when true
            self.is_identity = false
            out <<"END"
        <xsl:copy> 
          <xsl:apply-templates select="@*" />
          <xsl:apply-templates select="#{encode_path(rule.path_other)}/node()" />
        </xsl:copy>
END
          when false
            outln '        <xsl:copy-of select="." />'
          end
        end

        _generate_template rule.path_other, rule, opts do | mode |
          case mode
          when true
            self.is_identity = false
            out <<"END"
        <xsl:copy> 
          <xsl:apply-templates select="@*" />
          <xsl:apply-templates select="#{encode_path(rule.path)}/node()" />
        </xsl:copy>
END
          when false
            outln '        <xsl:copy-of select="." />'
          end
        end
      end

      def _generate_Delete rule, opts, mode
        case mode
        when true
          self.is_identity = false
          outln '        <!-- DELETED -->'
        when false
          outln '        <xsl:copy-of select="." />'
        end
      end


      def encode_path x
        case x
        when XPath
          x.xsl_escape
        when String
          SgmlEntity.ecode(x)
        else
          x
        end
      end


      ################################################################
      # Core Classes
      #


      def _generate_Content obj
        out obj.data
      end

      def _generate_String obj
        out obj
      end

      def _generate_Symbol obj
        out obj.to_s
      end

      def _generate_Fixnum obj
        out obj.to_s
      end

      def _generate_Float obj
        out obj.to_s
      end

      def _generate_Hash obj
        out "<hash>"
        obj.each do | k, v |
          out "<keyval>"
          out "<key>"
          _generate k
          out "</key>"
          out "<val>"
          _generate v
          out "</val>"
          out "</keyval>"
        end
        out "</hash>"
      end

    end # class
  end # module
end # module


class Object
  alias :id :object_id
end

