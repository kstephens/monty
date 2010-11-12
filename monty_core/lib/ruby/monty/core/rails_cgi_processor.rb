require 'monty/core'

require 'monty/core/processor'

module Monty
  module Core
    # Support Monty hooks into Rails.
    class RailsCgiProcessor < Processor
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
                                   :seeds => { :session_id => request.session.session_id },
                                   :content_type => response.content_type
                                 )
          @input_setup_proc && @input_setup_proc.call(self)
        end
        @input
      end

      # Called from RailsSupport::CgiResponseSupport#out_with_monty_support.
      def process(input_stream)
        _log { input.inspect }

        input_body = 
          case input_stream
          when IO
            input_stream.read
          when StringIO
            input_stream.string
          when String
            input_stream
          else
            raise TypeError, "input_stream: expected IO, StringIO, or String, given #{input_stream.class}"
          end
        
        input.body = input_body

        process_input!

        input.body
      rescue Exception => err
        
      end
    end
  end
end


