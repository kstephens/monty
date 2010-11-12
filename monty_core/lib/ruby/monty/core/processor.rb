module Monty
  module Core
    # Main Processor engine.
    class Processor
      HTTP_REFERER = "HTTP_REFERER".freeze

      include Monty::Core::Options
      include Monty::Core::Log
      include Monty::Core::Config

      # The ExperimentSet used to determine the active and applicable Experiment objects.
      attr_accessor :experiment_set

      # The active and appliciable Experiments from the set.
      attr_accessor :active_experiments, :applicable_experiments

      # The Input data.
      attr_accessor :input

      # A Proc to call after the Input object is created.
      # FIXME: Remove _proc.
      attr_accessor :input_setup_proc

      # A Proc to call before or after ActiveRecord::Base#process.
      attr_accessor :before_process, :after_process, :process_result
      
      # A Proc to call before or after #process_input!
      attr_accessor :before_process_input, :after_process_input

      # Error, if one occurred during #process_input!.
      attr_reader :error

      # If not false, output some debugging info.
      attr_accessor :debug


      def initialize_before_opts
        super
        @logger = $stderr
        @log_level = :debug
        @debug = false
        @before_process = @after_process =
        @before_process_input = @after_process_input = nil
        @error = nil
      end


      # Returns true if any Experiments are applicable.
      def is_active?
        input.content_type =~ /html/ && 
          ! applicable_experiments.empty?
      end


      # Returns a cached Array of applicable_experiments.
      def applicable_experiments
        @applicable_experiments ||=
          experiment_set.applicable_experiments(input)
      end


      # Returns a cached Array of applicable_experiments.
      def active_experiments
        @active_experiments ||=
          experiment_set.active_experiments(input)
      end


      # Returns the specified or default ExperimentSet.
      def experiment_set
        @experiment_set ||=
          Monty::Core::ExperimentSet.get
      end


      # Returns the cached XSL for an Experiment.
      def xsl_for_experiment e
        unless xsl = e.xsl
          xsl = Xslt.new
          xg = XsltGenerator.new(:output => xsl)
          xg.generate(e)
          e.xsl = xsl

          if @debug
            File.open("/tmp/monty-#{e.name}.xsl", "w+") do | fh |
              fh.write xsl.data
            end
          end
        end
        xsl
      end

      # Returns the cached XSL for a Rule.
      def xsl_for_rule r
        unless xsl = r.xsl
          e = r.experiment

          xsl = Xslt.new
          xg = XsltGenerator.new(:output => xsl)
          xg.generate(e, [ r ])
          r.xsl = xsl

          if @debug # || true
            File.open("/tmp/monty-#{e.name}-#{r.name}.xsl", "w+") do | fh |
              fh.write xsl.data
            end
          end
        end
        xsl
      end

      # Called around ActiveRecord::Base#process.
      # Invokes #before_process and #after_process Procs.
      def around_process! 
        (proc = @before_process) && proc.call(self)
        @process_result = yield
      ensure
        (proc = @after_process) && proc.call(@self)
      end


      # Subclasses should call this once input has been initialized.
      def process_input!
        input.applied_possibilities = [ ]

        @before_process_input && @before_process_input.call(self)

        forced_possibilities = input.forced_possibilities(experiment_set)
        _log { "  Forced possibilities #{forced_possibilities.map{|x| x.to_s}.inspect}" } if ! forced_possibilities.empty?

        experiments = active_experiments
        _log { "  Generating #{experiments.size} experiment parameter sets" }

        experiments.each do | e |
          xsl = xsl_for_experiment e
          xsl.parameters.each do | param |
            input.generate_parameter_value! e, param
          end
        end

        experiments = applicable_experiments
        _log { "  Applying #{experiments.size} experiments" }

        # Start with the original input body document.
        result = input.body

        experiments.each do | e |
          # Get the cached XSL for the Experiment.
          xsl = xsl_for_experiment e

          # Generate parameters based on entropy_stream.
          params = { }
          param_0 = nil # remember the first parameter.
          xsl.parameters.each do | param |
            if params[param]
              raise Monty::Core::Error, "param #{param.inspect} already computed!"
            end
            param_0 ||= (params[param] = input.parameter_value(e, param))
          end

          # Apply the Experiment's XSL and parameters to the input document.
          _log { "  Applying #{e.class} #{e.priority} #{e.name.inspect} as #{input.document_type} using input #{e.input_name.inspect} => #{input.seeds[e.input_name].inspect} with generated parameters #{params.inspect}" }

          # Determine the Possibility that was selected from the Experiment.
          # Keep track of it in the Input object.
          p = e.possibility_for_params params
          if p
            input.applied_possibilities << p
            _log { "Selected Experiment #{e.name.inspect} Possibility #{p.name.inspect} using #{param_0}" }
          end

          if @debug
            File.open("/tmp/monty-#{e.name}-input.txt", "w+") do | fh |
              fh.puts "params = #{params.inspect}"
              fh.write result
            end
          end

          # Apply single Experiment XSL. 
          if false
            xsl_processor = Monty::Core::XslProcessor.new(:xsl => xsl, 
                                                          :document_type => input.document_type,
                                                          :debug => @debug)
            
            result = xsl_processor.apply(result, params)
          else
            e.rules.each do | r |
              if @debug
                File.open("/tmp/monty-#{e.name}-#{r.name}-input.txt", "w+") do | fh |
                  fh.puts "params = #{params.inspect}"
                  fh.write result.to_s
                end
              end
              
              xsl = xsl_for_rule r
              
              _log { "  Applying #{e.class} #{e.priority} #{e.name.inspect} Rule #{r.name.inspect} as #{input.document_type} using input #{e.input_name.inspect} => #{input.seeds[e.input_name].inspect} with generated parameters #{params.inspect}" }
              
              xsl_processor = Monty::Core::XslProcessor.new(:xsl => xsl, 
                                                            :document_type => input.document_type,
                                                            :debug => @debug)
              
              result = xsl_processor.apply(result, params)
              
              if @debug
                File.open("/tmp/monty-#{e.name}-#{r.name}-output.txt", "w+") do | fh |
                  fh.write result.to_s
                end
              end
              
            end # rules
          end
          
          if @debug
            File.open("/tmp/monty-#{e.name}-output.txt", "w+") do | fh |
              fh.write result.to_s
            end
          end
        end # next Experiment

        # Replace the input body document with the last result.
        result = result.string unless String === result
        input.body = result
        input

      rescue Exception => err
        @error = err
        raise err

      ensure
        input.applied_possibilities.sort!{| a, b | a.id <=> b.id }
        input.applied_possibilities.uniq! # probably not necessary.

        @after_process_input && @after_process_input.call(self)
      end

    end # class
  end # module
end # module

