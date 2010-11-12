module Monty
  module Core
    #
    # Represents a set of all Experiments that are active.
    #
    # This usually interfaces to some configuration store of
    # Experiments (e.g.: Ruby code, YAML, ActiveRecord, etc.).
    #
    # That storage is implemented and managed elsewhere.
    #
    class ExperimentSet
      include Monty::Core::Options

      # Association: Collection of Experiments in this ExperimentSet.
      attr_accessor :experiments

      def initialize_before_opts
        super
        @experiments = [ ]
      end

      # Returns an Array of Experiments that are enabled during input.now, ordered by id.
      def active_experiments input
        experiments.select{|e| e.active?(input)}.sort_by{|e| e.id}
      end

      # Returns an Array of Experiments that are applicable to the Input, ordered by priority.
      def applicable_experiments input
        experiments.select{|e| e.applicable?(input)}.sort_by{|e| e.priority}
      end
     
      @@get_proc ||= nil
      # The Proc that returns the current ExperimentSet.
      def self.get_proc
        @get_proc
      end
      def self.get_proc= x
        @get_proc = x
      end

      # Returns the current ExperimentSet.
      def self.get
        (x = get_proc) && x.call
      end
      # By default return an empty ExperimentSet.
      self.get_proc ||= lambda { | | ExperimentSet.new(:experiments => [ ]) }

      # Helper for testing.
      def create_experiment opts = { }
        e = Monty::Core::Experiment.new(opts)
        experiments << e
        e
      end

      module Behavior
      end

      include Behavior
    end
  end
end
