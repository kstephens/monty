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
        end
        include Behavior
      end

    end # class

  end # module
end # module

