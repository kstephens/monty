module Monty
  module Core

    #
    # Represents a set of Experiments that are grouped and controlled together.
    #
    # An Experiment within an ExperimentGroup are enabled between the start and end time, 
    # and can be explicitly disabled en-mass.
    #
    class ExperimentGroup
      include Monty::Core::Options

      # Property: The name of this ExperimentGroup, must be globally unique.
      attr_accessor :name

      # Property: The description of this ExperimentGroup.
      attr_accessor :description

      # Property: The start and end time when this ExperimentGroup and all its Experiments are applicable.
      attr_accessor :start_time, :end_time

      # Property: Enable or disable this ExperimentGroup and all its Experiments.
      attr_accessor :enabled

      # Association: Collection of Experiments in this ExperimentGroup.
      attr_accessor :experiments

      def initialize_before_opts
        super
        @start_time = @end_time = nil
        @enabled = true

        @experiments = [ ]
      end

      # AR::B dummy method.
      def save!
        self
      end

      # Support for testing/programmic building.
      def create_experiment opts = { }
        e = Monty::Core::Experiment.new(opts.merge(:experiment_group => self))
        experiments << e
        e
      end

      module Behavior
        def enabled?
          enabled
        end

        # Returns an Array of Experiments that are enabled during input.now, ordered by id.
        def active_experiments input
          experiments.select{|e| e.active?(input)}.sort_by{|e| e.id}
        end
        
        # Returns an Array of Experiments that are applicable to the Input, ordered by priority.
        def applicable_experiments input
          experiments.select{|e| e.applicable?(input)}.sort_by{|e| e.priority}
        end
        
      end

      include Behavior
    end
  end
end
