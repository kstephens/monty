module Monty
  module Core
    class Possibility
      include Monty::Core::Options

      # Property: The name of this Posssibility, must be unique in its Experiment.
      attr_accessor :name

      # Property: The relative weight of this Possiblity in its Experiment.
      attr_accessor :weight

      # Property: The "column" index of this object in its Experiment, must be unique.
      attr_accessor :index

      # Asssociation: The Experiment that owns this Possiblity.
      attr_accessor :experiment

      module Behavior
        attr_accessor :weight_range

        def to_s
          super.sub(/>$/, " #{experiment.name}::#{name} >")
        end

        # Returns a Range for this Possibility within [0, Experiment#weight_sum).
        def weight_range
          experiment.compute_weight_ranges! unless @weight_range
          @weight_range
        end

        # Returns a Range for this Possibility within [0.0, 1.0).
        def probability_range
          @probabilty_range ||=
            (wr = weight_range) &&
            (wsf = experiment.weight_sum.to_f) &&
            (wr.min.to_f  / wsf) ...
            (wr.last.to_f / wsf)
        end

        # Returns true if this Possibility enables no Rules.
        def identity?
          experiment.rules.all?{|r| ! experiment[self, r]}
        end
      end

      include Behavior
    end
  end
end
