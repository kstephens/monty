module Monty
  module Core
    #
    # Represents a set of Rules that are enabled/disable for a set of Possibilities.
    #
    # Each Possibility has a weight that determines how often each enabled Rule is applied.
    # An Experiment is appliciable to URIs that match.
    # An Experiment may also be enabled by a referrer URI.
    # An Experiment can be explicitly disabled, yet is temporally
    # controlled by its ExperimentGroup.
    #
    # Example:
    #
    #        \
    #   Rules \ Possibilities
    #          \
    #           \    A  |  B  |  C  |
    #            \| 50% | 25% | 25% |
    #             +-----------------------------------------
    #   R1        |     |  x  |     |
    #   R2        |     |  x  |     |
    #   R3        |     |     |  x  |
    #   
    # The above example will generate:
    # * a result, using no Rules, 50% of the time,
    # * a result, using Rules R1 and R2, 25% of the time,
    # * a result, using Rules R3, 25% of the time.
    #
    class Experiment
      include Monty::Core::Options

      # Property: The name of this Experiment, must be unique within its ExperimentGroup.
      attr_accessor :name

      # Property: The description of this Experiment.
      attr_accessor :description

      # Property: The priority of this Experiment relative to other Experiments.
      attr_accessor :priority

      # Property: Enable or disable this Experiment.
      attr_accessor :enabled

      # Property: The base URI of the website that must match Input#website.
      attr_accessor :website

      # Property: Symbol naming the input, defaults to :session_id.
      attr_accessor :input_name

      # Association: The ExperimentGroup this belongs to.
      attr_accessor :experiment_group

      # Association: Collection of Possibilities (columns).
      attr_accessor :possibilities

      # Association: Collection of Rules (rows).
      attr_accessor :rules
   
      # Association: Collection of all RuleSelections based on each Possibility and Rule.
      attr_accessor :rule_selections


      alias :id :object_id

      def initialize_before_opts
        super
        @name = nil
        @input_name = :session_id
        @enabled = true
        @uri_pattern = nil

        @experiment_group = nil
        @possibilities = [ ]
        @rules = [ ]
        @rule_selections = [ ]
      end

      # AR::B dummy method.
      def save!
        self
      end

      # Creates the appropriate Rule object.
      def create_rule(type, *opts)
        r = Rule.create_rule(type, *opts)
        self << r
        r
      end

      # Creates the appropriate Possibility object.
      def create_possibility(*opts)
        p = Possibility.new(*opts)
        self << p
        p
      end


      module Behavior
        # The cached Xslt generated in Processor.
        attr_accessor :xsl

        # Property: if this Experiment is applicable. matches the Input.uri 
        attr_accessor :uri_pattern
        
        # Property: if this Experiment is applicable, matches the Input.referrer.
        attr_accessor :referrer_pattern
        
        def to_s
          super.sub(/>$/, " #{name} >")
        end

        # Returns true if this Experiment and its ExperimentGroup are enabled.
        def enabled?
          self.enabled && (experiment_group ? experiment_group.enabled? : true)
        end

        # Return the ExperimentGroup start_time or nil.
        def start_time
          experiment_group && experiment_group.start_time
        end

        # Return the ExperimentGroup end_time or nil.
        def end_time
          experiment_group && experiment_group.end_time
        end

        # Sets the UriPattern based on a String or Array.
        def uri_pattern= x
          case x
          when UriPattern
          when String
            x = UriPattern.new(:string => x)
          when Array
            x = UriPattern.new(:patterns => x)
          else
            raise TypeError, "uri_pattern=: expected UriPattern, String, or Array, given #{x.class.name}"
          end
          @uri_pattern = x
        end

        # Sets the UriPattern based on a String or Array.
        def referrer_pattern= x
          case x
          when UriPattern
          when String
            x = UriPattern.new(:string => x)
          when Array
            x = UriPattern.new(:patterns => x)
          else
            raise TypeError, "referrer_pattern=: expected UriPattern, String, or Array, given #{x.class.name}"
          end
          @referrer_pattern = x
        end

        # Add new Possibility or Rule.
        def << x
          case x
          when Possibility::Behavior
            self.possibilities ||= [ ]
            x.index = possibilities.size
            x.experiment = self
            @possibilities_ordered = nil
            possibilities << x
          when Rule::Behavior
            self.rules ||= [ ]
            x.index = rules.size
            x.experiment = self
            rules << x
          else
            raise TypeError
          end
          self
        end
        
        def possibilities_ordered
          @possibilities_ordered ||=
            possibilities.sort_by{|p| p.index}
        end

        # Returns the sum of all Possibility weights.
        def weight_sum
          unless @weight_sum
            sum = min = 0
            possibilities_ordered.each do | p |
              max = min + p.weight
              p.weight_range = (min ... max)
              min = max
            end
            @weight_sum = min
          end
          @weight_sum
        end
        alias :compute_weight_ranges! :weight_sum


        # Returns the Possibility that would be selected based on this Experiments XSL params.
        def possibility_for_params params
          param_0 = params.values.first # UGLY!!!
          possibilities.find { | p | p.probability_range.include?(param_0) }
        end


        # Returns true or false if a Rule is enabled for a particular Possibility.
        def [] pos, rule
          pos, rule = pos_rule_index pos, rule
          if rs = rule_selections.find{|x| x.possibility == pos && x.rule == rule}
            ! ! rs.enabled
          end
        end
        

        # Enables/disables a Rule for a particular Possibility.
        def []= pos, rule, value
          pos, rule = pos_rule_index pos, rule
          unless rs = rule_selections.find{|x| x.possibility == pos && x.rule == rule}
            rs = rule.new_selection
            rule_selections << rs
            rs.possibility = pos
          end
          rs.enabled = ! ! value
          rs.save!
          
          rs
        end

        def pos_rule_index pos, rule
          case pos
          when Possibility::Behavior
            pos
          when String
            pos = possibilities.find{|x| pos === x.name }
          when Integer
            pos = possibilities[pos]
          else
            raise TypeError, "pos: expected Possibility, String, Integer: given #{pos.class}"
          end
          
          case rule
          when Rule::Behavior
            rule
          when String
            rule = rules.find{|x| rule === x.name }
          when Integer
            rule = rules[rule]
          else
            raise TypeError, "rule: expected Rule, String, Integer: given #{rule.class}"
          end
          
          [ pos, rule ]
        end

        # Returns true if this Experiment is active during input.now.
        def active? input
          (((x = start_time) ? x <= input.now : true) && 
           ((x = end_time) ? input.now <= x : true))
        end

        # Returns true if this Experiment is applicable to the Input.
        def applicable? input
          enabled? &&
            active?(input) &&
            ((x = website) ? x === input.website.to_s : true) &&
            ((x = uri_pattern) ? x === input.uri.to_s : true) &&
            ((x = referrer_pattern) ? x === input.referrer.to_s : true)
        end
        
      end
      
      include Behavior
    end # class
  end # module 
end # module

