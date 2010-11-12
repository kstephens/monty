require 'monty/core'

require 'monty/core/rails_cgi_processor'
require 'stringio'

module Monty
  module Core
    # Support Monty hooks into Rails.
    module RailsSupport
      def self.activate!
        ActionController::AbstractRequest.instance_eval do
          include Monty::Core::RailsSupport::AbstractRequestSupport
        end
        ActionController::AbstractResponse.instance_eval do
          include Monty::Core::RailsSupport::AbstractResponseSupport
        end
        ActionController::CgiResponse.instance_eval do
          include Monty::Core::RailsSupport::CgiResponseSupport
        end
        ActionController::Base.instance_eval do 
          include Monty::Core::RailsSupport::ActionControllerSupport
        end
      end

      # Monty support for ActionController::AbstractResponse.
      module AbstractRequestSupport
        # True if Monty Experiments were already applied.
        attr_accessor :monty_applied
      end

      # Monty support for ActionController::AbstractResponse.
      module AbstractResponseSupport
        # Reference to the Request that initiated this Response.
        attr_accessor :request
      end

      # Sets response.request.
      module ActionControllerSupport
        def self.included target
          super
          target.class_eval do 
            alias :process_without_monty_support :process unless method_defined? :process_without_monty_support
            alias :process :process_with_monty_support
          end
        end

        # Set up response.request.
        def process_with_monty_support request, response, method = :perform_action, *arguments
          response.request = request
          process_without_monty_support request, response, method, *arguments
        end
      end # module

      # Dispatch Rails response.body through Monty::Core::RailsCgiProcessor.
      module CgiResponseSupport
        def self.included target
          super
          target.class_eval do 
            alias :out_without_monty_support :out unless method_defined? :out_without_monty_support
            alias :out :out_with_monty_support
          end
        end

        def out_with_monty_support output = $stdout
          mp = Monty::Core::RailsCgiProcessor.new(:request => self.request, :response => self)

          # STDERR.puts "out_with_monty_support: input = #{mp.input.inspect}"
        
          # Monty is active, if it has Experiments that apply to this content.
          #
          # If Monty is active, capture the output of the response into a String.
          # Otherwise, just send the the response verbatim.
          #
          # Avoid applying Monty to the request more than once.
          capture_output = nil
          if mp.is_active? && ! request.monty_applied
            Timer.new(:monty_capture_output) do
              capture_output = StringIO.new('')
              out_without_monty_support capture_output
            end.log(mp.logger)
          else
            return out_without_monty_support output
          end

          # Do not recur if Monty failed once.
          request.monty_applied = true
          
          # HTTP header and body have been captured in capture_output.string.
          begin
            Timer.new(:monty_apply_experiments) do
              
            # Parse the HTTP header and body.
            http_body = capture_output.string.dup
            http_body.sub!(/\A(.*?\n\r?\n\r?)/m, '')
            http_header = $1 || ''
              
            # Get the transformed HTTP body.
            http_body = mp.process(http_body)
              
            # Save it as the body and continue processing the output.
            @body = http_body

            end.log(mp.logger)
          rescue Exception => err
            # If an error occurred, log and process the original output.
            STDERR.puts "ERROR: Monty: #{err.inspect}\n#{err.backtrace * "\n"}"
            @body = capture_output.string
            @headers['X-Monty-Error'] = err.class.name.to_s

          ensure
            Timer.new(:monty_send_output) do
              @headers['X-Monty-Possibilities'] = (mp.input.applied_possibilities || [ ]).map{|p| p.id}.join(",")
              out_without_monty_support output
            end.log(mp.logger)
          end
        end # begin
      end # module

      class Timer
        def initialize name = nil
          @name = name || object_id
          if block_given?
            measure! { yield }
          end
        end

        def measure!
          @t0 = Time.now.to_f
          @t1 = nil
          result = yield
          @t1 = Time.now.to_f
          result
        ensure
          @elapsed = @t0 && @t1 && (@t1 - @t0)
        end

        def to_s 
          "Timer: #{@name.inspect} #{@elapsed.inspect}"
        end

        def log logger = nil
          logger.info { "Monty: #{self}" } if logger
        end
      end

    end # module
  end # module
end # module
