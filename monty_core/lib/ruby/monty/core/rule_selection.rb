module Monty
  module Core
    # Enable/Disable a Rule Possibility.
    # See Experiment#[Possibility, Rule] method.
    class RuleSelection
      include Monty::Core::Options
      
      # Association
      attr_accessor :possibility
      
      # Association
      attr_accessor :rule
      
      # Property
      attr_accessor :enabled
      
      # Placeholder for AR::B#save!
      def save!
        self
      end
      
      module Behavior
        def enabled?
          enabled
        end
      end
      
      include Behavior
    end
  end # module
end # module

 
