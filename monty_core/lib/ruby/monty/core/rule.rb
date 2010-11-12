module Monty
  module Core
    # Base class for transformations rules.
    class Rule
      include Monty::Core::Options

      # Property
      attr_accessor :name, :description

      # Ordering in Experiment#rules.
      attr_accessor :index

      # Association
      attr_accessor :experiment


      module Behavior
        # Property
        attr_accessor :path

        # The cached Xslt generated in Processor.
        attr_accessor :xsl

        def to_s
          super.sub(/>$/, " #{name} >")
        end

        # Sets the path XPath based on a String or Array.
        def path= x
          case x
          when XPath
          when String
            x = XPath.new(:string => x)
          else
            raise TypeError, "path=: expected XPath or String, given #{x.class.name}"
          end
          @path = x
        end

        def self.included target
          super
          target.extend(ClassMethods)
        end
        
        module ClassMethods
          def rule_class
            @@rule_class ||= 
              { }
          end

          def register_rule name
=begin
            $stderr.puts "register_rule"
            $stderr.puts "  self = #{self.inspect}"
            $stderr.puts "  name = #{name.inspect}"
=end

            raise TypeError unless Class === self
            rule_class[name.to_sym] = 
            rule_class[name.to_s] = 
              self
          end
          
          def create_rule type, *opts
=begin
            $stderr.puts "create_rule"
            $stderr.puts "  self = #{self.inspect}"
            $stderr.puts "  name = #{type.inspect}"
            $stderr.puts "  rule_class = #{rule_class.inspect}"
=end

            rule_class[type].new(*opts)
          end
        end
      end
      include Behavior


      # Create a new RuleSelection for this Rule.
      def new_selection
        Monty::Core::RuleSelection.new(:rule => self)
      end


      # Changes an Attribute of an element.
      class ChangeAttribute < self
        register_rule :change_attribute

        # Property
        attr_accessor :attribute_name

        module Behavior
          attr_accessor :attribute_value
          
          def to_s
            "change the #{attribute_name} attribute of #{path} to #{attribute_value.inspect}"
          end

          def apply_to_dom_element! element, state
            a_name = attribute_name.to_s
            old_value = nil
            new_value = attribute_value.to_s
            new_value = new_value.gsub(/\{\{\.\}\}/) do | m |
              old_value ||= element[a_name].to_s
            end
            element[a_name] = new_value
          end
        end
        include Behavior
      end

      # Changes the "class" attribute of an element.
      class ChangeClass < ChangeAttribute
        register_rule :change_class

        module Behavior
          # Property
          attr_accessor :css_class

          ATTRIBUTE_NAME = 'class'.freeze
          def attribute_name 
            ATTRIBUTE_NAME
          end

          def css_class= x
            self.attribute_value = @css_class = x
          end
        end
        include Behavior
      end
 
      # Changes the "style" attribute of an element.
      class ChangeStyle < ChangeAttribute
        register_rule :change_style

        module Behavior
          # Property
          attr_accessor :css_style

          ATTRIBUTE_NAME = 'style'.freeze
          def attribute_name 
            ATTRIBUTE_NAME
          end

          def css_style= x
            self.attribute_value = @css_style = x
          end
        end
        include Behavior
      end

      # Changes the content of an element.
      class ChangeContent < self
        register_rule :change_content

        # Property
        attr_accessor :content

        module Behavior
          def to_s
            "change content of #{path}"
          end

          def apply_to_dom_element! element, state
            # Compute new value.
            new_value = content
            new_value = new_value.data if new_value.respond_to? :data
            new_value = new_value.to_s
            new_value = new_value.gsub(/\{\{\.\}\}/) do | m |
              old_value ||= element.inner_xml
              $stderr.puts "   #{self.name} old_value=#{old_value.inspect}"; old_value
            end

            # Remove all children.
            element.each do | c |
              c.remove!
            end

            # Insert Raw HTML.
            new_value = XML::Node.new_text(new_value)
            new_value.output_escaping = false
            element << new_value
          end
        end
        include Behavior
      end

      # Swaps the content of two elements.
      class SwapContent < self
        register_rule :swap_content

        # Property
        attr_accessor :path_other

        # Sets the path_other XPath based on a String or Array.
        def path_other= x
          case x
          when XPath
          when String
            x = XPath.new(:string => x)
          else
            raise TypeError, "path_other=: expected XPath or String, given #{x.class.name}"
          end
          @path_other = x
        end

        module Behavior
          def to_s
            "swap content of #{path} with #{path_other}"
          end

          def apply_to_dom_element! element, state
            children =
              state["self-#{self.object_id}"] ||= element.children.dup

            # Remove our elements.
            element.children.each do | c |
              c.remove!
            end

            other_children = nil
            others = element.doc.find(path_other.to_s)
            others.each do | other |
              other_children ||=
                state["other-#{self.object_id}"] ||= other.children.dup

              # Remove its children.
              other.children.each do | c |
                c.remove!
              end

              # Add the old children.
              children.each do | c |
                other << c.copy(true)
              end
            end

            # Copy others into this element.
            (other_children || EMPTY_ARRAY).each do | c |
              element << c.copy(true)
            end
          end
        end
        include Behavior
      end
      
      # Deletes an element.
      class Delete < self
        register_rule :delete

        module Behavior
          def to_s
            "delete #{path}"
          end

          def apply_to_dom_element! element, state
            #(state[:at_end] ||= [ ]) << lambda do | |
              element.remove!
            #end
          end
        end
        include Behavior
      end

    end # class

  end # module
end # module

