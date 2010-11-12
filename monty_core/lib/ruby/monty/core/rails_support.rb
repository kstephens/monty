require 'monty/core'

require 'monty/core/rails_cgi_processor'
require 'stringio'

module Monty
  module Core
    # Support Monty hooks into Rails.
    module RailsSupport
      def self.activate!
        case
        # Rails 3
        when defined? ActionDispatch::Request
          ActionDispatch::Request.instance_eval do
            include Monty::Core::RailsSupport::RequestSupport
          end
          ActionController::Base.instance_eval do
            include Monty::Core::RailsSupport::ControllerSupportRails3
          end
         
        # Rails 1.2
        when defined? ActionController::AbstractRequest
          ActionController::AbstractRequest.instance_eval do
            include Monty::Core::RailsSupport::RequestSupport
          end

          ActionController::AbstractResponse.instance_eval do
            include Monty::Core::RailsSupport::ResponseSupport
          end

          ActionController::CgiResponse.instance_eval do
            include Monty::Core::RailsSupport::CgiResponseSupportRails12
          end

          ActionController::Base.instance_eval do 
            include Monty::Core::RailsSupport::ActionControllerSupportRails12
          end
         else
          raise "Unexpected Rails version?"
        end
      end

      # Monty support for:
      # * Rails 1.2 ActionController::AbstractRequest
      # * Rails 3   ActionDispatch::Request
      module RequestSupport
        # True if Monty Experiments were already applied.
        attr_accessor :monty_applied
      end

      # Monty support for Rails 1.2 ActionController::AbstractResponse.
      module ResponseSupport
        # Reference to the Request that initiated this Response.
        attr_accessor :request
      end

      # Sets response.request in Rails 1.2.
      module ActionControllerSupportRails12
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

      X_Monty_Error = 'X-Monty-Error'.freeze
      X_Monty_Possibilities = 'X-Monty-Possibilities'.freeze

      # Support for Rails 3 ActionController::Base#to_a.
      module ControllerSupportRails3
        def self.included target
          super
          target.class_eval do 
            alias :to_a_without_monty_support :to_a unless method_defined? :to_a_without_monty_support
            alias :to_a :to_a_with_monty_support
          end
        end

        def to_a_with_monty_support
          applied_possibilities = nil
          request = @_request
          mp = Monty::Core::Rails3Processor.new(:request => request, :response => self)

          # STDERR.puts "to_a_with_monty_support: input = #{mp.input.inspect}"
        
          # Monty is active, if it has Experiments that apply to this content.
          #
          # If Monty is active, capture the output of the response into a String.
          # Otherwise, just send the the response verbatim.
          #
          # Avoid applying Monty to the request more than once.
          capture_result = nil
          if mp.is_active? && ! request.monty_applied
            Timer.new(:monty_capture_output) do
              capture_result = to_a_without_monty_support
            end.log(mp.logger)
          else
            return to_a_without_monty_support
          end

          # [ status, headers, response_body ] ||
          # response
          status, headers, response_obj = capture_result
          if false
            $stderr.puts "input status  = #{status.class} #{status}"
            $stderr.puts "input headers = #{headers.class} #{headers.inspect}"
            $stderr.puts "input response_obj = #{response_obj.class}"
          end

          # Get a String rep of the Response body.
          response_body = response_obj
          response_body = response_body.body if ActionDispatch::Response === response_body
          response_body = response_body.respond_to?(:join) ? response_body.join(EMPTY_STRING) : response_body
          response_body = response_body.to_s

          # Do not recur if Monty failed once.
          request.monty_applied = true
          
          # HTTP body has been captured in response_body.
          begin
            Timer.new(:monty_apply_experiments) do
              # Parse the HTTP header and body.
              http_body = response_body
              
              if false
                $stderr.puts "http_body ================="
                $stderr.puts http_body
                $stderr.puts "==========================="
              end

              # Get the transformed HTTP body.
              http_body = mp.process(http_body)

              # Save it as the body and continue processing the output.
              response_body = http_body

              if false
                $stderr.puts "response_body  =================="
                $stderr.puts response_body
                $stderr.puts "================================="
              end
            end.log(mp.logger)

          rescue Exception => err
            # If an error occurred, log and process the original output.
            STDERR.puts "ERROR: Monty: #{err.inspect}\n#{err.backtrace * "\n"}"
            headers[X_Monty_Error] = err.class.name.to_s
            
          ensure
            applied_possibilities = (mp.input.applied_possibilities || EMPTY_ARRAY).map{|p| p.id}.join("_")
            # Log the Possibilities in the Header.
            headers[X_Monty_Possibilities] = applied_possibilities
          end

          # Append Possibilities to ETags to prevent cache fusion.
          if etag = headers["ETag"]
            # Handle annoying pre-escaped, pre-quoted header values.
            headers["ETag"] = etag.sub(/(")\Z|\Z/) { | m | '-M' + applied_possibilities + $1 }
          end

          # Return result.
          if response_obj.respond_to?(:body)
            response_obj.body = response_body
          else
            response_obj = [ response_body ]
          end
          
          if false
            $stderr.puts "output status  = #{status.class} #{status}"
            $stderr.puts "output headers = #{headers.class} #{headers.inspect}"
            $stderr.puts "output response_obj = #{response_obj.class}"
          end

          [ status, headers, response_obj ]
        end # begin
      end

      # Dispatch Rails 1.2 response.body through Monty::Core::RailsCgiProcessor.
      module CgiResponseSupportRails12
        def self.included target
          super
          target.class_eval do 
            alias :out_without_monty_support :out unless method_defined? :out_without_monty_support
            alias :out :out_with_monty_support
          end
        end

        def out_with_monty_support output = $stdout
          mp = Monty::Core::Rails12CgiProcessor.new(:request => self.request, :response => self)

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
              http_body.sub!(/\A(.*?\n\r?\n\r?)/m, EMPTY_STRING)
              http_header = $1 || EMPTY_STRING
              
              # Get the transformed HTTP body.
              http_body = mp.process(http_body)
              
              # Save it as the body and continue processing the output.
              @body = http_body

            end.log(mp.logger)
          rescue Exception => err
            # If an error occurred, log and process the original output.
            STDERR.puts "ERROR: Monty: #{err.inspect}\n#{err.backtrace * "\n"}"
            @body = capture_output.string
            @headers[X_Monty_Error] = err.class.name.to_s

          ensure
            Timer.new(:monty_send_output) do
              @headers[X_Monty_Possibilities] = (mp.input.applied_possibilities || EMPTY_ARRAY).map{|p| p.id}.join(",")
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
          return unless logger
          case 
          when logger.respond_to?(:info)
            logger.info { "Monty: #{self}" }
          when logger.respond_to?(:puts)
            logger.puts "Monty: #{self}"
          else
            raise Error, "Cannot support logger of #{logger.class}"
          end
        end
      end

    end # module
  end # module
end # module
