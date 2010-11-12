module Monty
  module Core
    # Input data for Monty engine.
    class Input
      include Monty::Core::Options

      # The base URI of the website.
      attr_accessor :website

      # The URI of the request.
      # Typically the URI path without query parameters.
      attr_accessor :uri

      # The time of the request.
      attr_accessor :now

      # The CGI URI query parameters.
      # Provides hook for ?_monty_seed= override.
      attr_accessor :query_parameters

      # The Referrer URI.
      attr_accessor :referrer

      # The HTTP document body.
      attr_accessor :body
      
      # The HTTP MIME Content-Type.
      attr_accessor :content_type
      
      # Actual document input type, :html or :xml
      attr_accessor :document_type

      # The seeds used for each input type.
      attr_accessor :seeds

      # The EntropyStream that produces pseudo-random data from the seed.
      # The output of this stream is used as parameters to each Experiment's XSL.
      attr_accessor :entropy_stream

      # A Hash of Hashes that map each Experiment id to a Hash of parameter key Symbols and parameter value Floats.
      attr_reader :experiment_parameter_values

      # If true, the entropy_streams have been overridden.
      attr_reader :overridden
      alias :overridden? :overridden

      # A set of Possibilities applied to the input, sorted by #id.
      attr_accessor :applied_possibilities

      # A set of forced Possibilities.
      attr_accessor :forced_possibilities


      def initialize_before_opts
        super
        @now = nil
        @seeds = { }
        @overridden = false
        @entropy_streams = { }
        @experiment_parameter_values = { }
        @document_type = :html
        @query_parameters = EMPTY_HASH
        @applied_possibilities = nil
      end


      # Defaults to Time.now.
      def now
        @now ||=
          Time.now
      end

      def session_id 
        @seeds[:session_id]
      end

      def session_id= x
        @seeds[:session_id] = x
      end

      # Returns the EntropyStream object with the appropriate seed based on the input_name.
      # ?_monty_seed=... query_parameters overrides any other input value.
      def entropy_stream input_name
        unless es = @entropy_streams[input_name]
          if seed = query_parameters[MONTY_SEED_PARAM]
            @overridden = true
            seed = @seeds[input_name] = "#{input_name}#{seed}"
          else
            seed = @seeds[input_name]
          end
          # $stderr.puts "using seed #{seed.inspect} for #{input_name.inspect}"
          es = @entropy_streams[input_name] = EntropyStream.new(:seed => seed)
        end
        es
      end
      MONTY_SEED_PARAM = '_monty_seed'.freeze
      MONTY_SEED_PARAM_RX = %r{#{MONTY_SEED_PARAM}=[^&]*}
      MONTY_POSSIBILITY = '_monty_possibility'.freeze

      # Generates an XSL parameter value for an experiment using the appropriate entropy stream.
      def generate_parameter_value! experiment, parameter
        h = (@experiment_parameter_values[experiment.name] ||= { })
        if h[parameter]
          raise Monty::Core::Error, "parameter already generated for #{experiment.id} #{parameter.inspect}"
        end

        value = nil

        # Check for forced possibilities.
        if @overridden && (fp = @forced_possibilities) && ! fp.empty?
          # $stderr.puts "  Forced possibilities #{fp.inspect}"
          # $stderr.puts "    e.ps = #{experiment.possibilities.map{|p| p.id}.inspect}"
          if fp = experiment.possibilities.find{|p| fp.find{|p_id| p.id == p_id } }
            r = fp.probability_range
            value = (r.first + r.last) * 0.5
            # $stderr.puts "  Forced Possibility #{fp.name} using value = #{value} in #{r.inspect}"
          else
            value = -1.0 # DO NOTHING!
            # $stderr.puts "  Forced Possibility disabled Experiment #{experiment.name} using value = #{value}"
          end
        end

        value ||= entropy_stream(experiment.input_name).to_f

        # $stderr.puts "  generate_parameter_value! #{experiment.name}, #{parameter.inspect} => #{value.inspect}"

        h[parameter] = value
      end

      # Returns the parameter value for an experiment.
      def parameter_value experiment, parameter
        (@experiment_parameter_values[experiment.name] || EMPTY_HASH)[parameter] or 
          raise Monty::Core::Error, "parameter #{experiment.id} #{parameter.inspect} does not exist"
      end


      def force_possibility! poss
        if poss
          @overridden = true
          (@forced_possibilities ||= [ ]) << (Possibility ? poss.id : poss.to_i)
          @forced_possibilities.uniq!
        end
        self
      end

      # Returns an Array of Possibilities ids.
      # Can be specified using:
      #
      #   ?_monty_possibility=#{Possibility#id},...
      #   ?_monty_possibility=#{Experiment#name}:#{Possibility#name},...
      #
      # If _monty_possibility is set,
      # and an Experiment does not have a Possibility specified, 
      # the Experiment will be disabled,
      #
      # This mechanism can be used for previewing Possibilities.
      #
      def forced_possibilities(experiment_set)
        unless @forced_possibilities
          unless x = query_parameters[MONTY_POSSIBILITY]
            return @forced_possibilities = EMPTY_ARRAY
          end
          @overridden = true
          x = x.split(',') unless Array === x
          x.map! do | name |
            case name
            when /^\d+$/
              name.to_i
            when /^([^:]+):([^:]+)$/
              e_name, p_name = $1, $2
              es = experiment_set.applicable_experiments(self)
              e = es.find{|e| e.name == e_name}
              # $stderr.puts "Found e = #{e} for #{e_name}"
              p = e && e.possibilities.find{|p| p.name == p_name}
              # $stderr.puts "Found p = #{p} for #{p_name}"
              p && p.id
            else
              nil
            end
          end
          x.compact!
          # $stderr.puts "forced_possibilities = #{x.inspect}"
          @forced_possibilities = x
        end
        @forced_possibilities
      end
    end
  end
end

