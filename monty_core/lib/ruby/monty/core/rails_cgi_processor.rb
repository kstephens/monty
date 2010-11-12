# TODO: Rename this file to rails_processor.rb
require 'monty/core'

require 'monty/core/processor'

module Monty
  module Core
    # Support Monty hooks into Rails X request and response.
    class RailsProcessor < Processor
      attr_accessor :request, :response

      include Monty::Core::Options

      # Returns the Monty::Core::Input object based on the Rails request/response objects.
      # Calls input_setup_proc, if set.
      def input
        unless @input
          @input =
            Monty::Core::Input.new(:uri => request.path,
                                   :referrer => request.env[HTTP_REFERER],
                                   :query_parameters => request.query_parameters,
                                   :seeds => { :session_id => session_id },
                                   :content_type => response.content_type
                                 )
          @input_setup_proc && @input_setup_proc.call(self)
          $stderr.puts "#{self} seeds = #{@input.seeds.inspect}"
        end
        @input
      end

      # Called from RailsSupport::*#*_with_monty_support.
      def process(input_stream)
        _log { input.inspect } if @debug

        input_body = 
          case input_stream
          when IO
            input_stream.read
          when StringIO
            input_stream.string
          when String
            input_stream
          when Array
            input_stream.join(EMPTY_STRING)
          else
            raise TypeError, "input_stream: expected IO, StringIO, String, or Array given #{input_stream.class}"
          end
        
        input.body = input_body

        process_input!

        input.body

      rescue Exception => err
        @error = err
        $stderr.puts "#{self} #{err.inspect}\n#{err.backtrace * "\n"}"
        input.body
      end
    end # class

    # Support Monty hooks into Rails 3.
    class Rails3Processor < RailsProcessor
      # Rails 1.2 support for request.session[:id]
      def session_id
        @request.session_options[:id]
      end
    end

    # Support Monty hooks into Rails 1.2.
    class Rails12Processor < RailsProcessor
      # Rails 1.2 support for request.session.session_id
      def session_id
        @request.session.session_id
      end
    end
  end
end


